'use strict';

const _ = require('lodash');
const functions = require('firebase-functions');
const {Firestore} = require('@google-cloud/firestore');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");
const rateLimit = require('axios-rate-limit');

// -----------------------------------------------------------------------------
// ---- Constants
// -----------------------------------------------------------------------------
const config = {
  concurrency: {
    maxProblemsLoadingInParallel: 10,
    maxContestsLoadingInParallel: 10
  },
  batchLimits: {
    maxContestsInOneBatch: 100,
  },
  contestHistogram: {
    maxBuckets: 25,
    maxScore: 0.5  // expressed as max points to be scored in the contest
  },
  forbiddenContests: [
    693, 726, 728, 826, 857, 874, 885, 905, 1048, 1049, 1050, 1094, 1222, 1224,
    1226, 1258
  ]
}
const forbiddenContests = [];

// -----------------------------------------------------------------------------
// ---- Globals
// -----------------------------------------------------------------------------

admin.initializeApp();
const db = admin.firestore();
const http = rateLimit(axios.create(), { maxRPS: 5 })
const FieldValue = admin.firestore.FieldValue;

// -----------------------------------------------------------------------------
// ---- ret
// -----------------------------------------------------------------------------

const ret = {
  nothing: {
    results: 0,
    errors: []
  },
  error: (err) => ({
    results: 0,
    errors: [err]
  }),
  result: {
    results: 1,
    errors: []
  },
  combine: (r1, r2) => ({
    results: r1.results + r2.results,
    errors: [...r1.errors, ...r2.errors]
  }),
  toString: (r) => `#${r.results}` + ((r.errors.length === 0) ? '' : `, errors: ${r.errors}`)
};

// -----------------------------------------------------------------------------
// ---- Entry points
// -----------------------------------------------------------------------------

exports.loadContests = functions.runWith({
  timeoutSeconds: 540,
  memory: '1GB'
}).https.onRequest(async (req, res) => {
  const newContests = await loadAllContests();
  res.json({newContests: ret.toString(newContests)})
});

exports.loadProblems = functions.runWith({
  timeoutSeconds: 540,
  memory: '1GB'
}).https.onRequest(async (req, res) => {
  const newProblems = await loadAllProblems();
  res.json({newProblems: ret.toString(newProblems)})
});

exports.loadUserData = functions.https.onRequest(async (req, res) => {
  const user = req.query.user;
  if (!user) {
    res.json('Please provide <user> query param');
  } else {
    res.json(await loadUser(user));
  }
});

// -----------------------------------------------------------------------------
// ---- Contests
// -----------------------------------------------------------------------------

async function loadAllContests() {
  const response = await http.get('https://codeforces.com/api/contest.list?gym=false');
  const contests = response.data.result;
  const toLoad = await async.filterLimit(
      contests, config.concurrency.maxContestsLoadingInParallel, needToLoadContest);

  console.log(`Fetched contests: ${contests.length}, need loading: ${toLoad.length}`);
  const newContests = await async.mapLimit(
      _.take(toLoad, config.batchLimits.maxContestsInOneBatch),
      config.concurrency.maxContestsLoadingInParallel,
      loadContest);

  const processed = newContests.reduce(ret.combine, ret.nothing);
  functions.logger.log(`Contests fetched: ${contests.length}, need loading: ${toLoad.length}, loaded: ${ret.toString(processed)}`);
  return processed;
}

async function needToLoadContest(contest) {
  try {
    if (contest.phase !== 'FINISHED') return false;
    if (config.forbiddenContests.includes(contest.id)) return false;

    const contestRef = db.collection('contests').doc(contest.id.toString())
    const contestData = await contestRef.get();
    return !contestData.exists;

  } catch (error) {
    functions.logger.error(`Error needToLoadContest contest: ${contest.id}: ${error}`);
    return false;
  }
}

async function loadContest(contest) {
  try {
    console.log(`Loading new contest: ${contest.id}`);
    const contestRef = db.collection('contests').doc(contest.id.toString())
    contest.details = await getContestDetails(contest, contestRef);

    await contestRef.set(contest);
    console.log(`Finished processing new contest: ${contest.id}`);
    return ret.result;

  } catch (error) {
    functions.logger.error(`Error fetching contest: ${contest.id}: ${error}`);
    return ret.error(contest.id);
  }
}

async function getContestDetails(contest, contestRef) {
  console.log(`Fetching details of contest: ${contest.id}`);
  const response = await http.get('https://codeforces.com/api/contest.standings'
    + `?contestId=${contest.id}&showUnofficial=false`);
  const result = response.data.result;
  const details = { problems: result.problems };

  if (contest.type === 'CF') {
    const maxPoints = _.sumBy(result.problems, (problem) => problem.points);
    const bucketSize = maxPoints * config.contestHistogram.maxScore / config.contestHistogram.maxBuckets;
    const points = _(result.rows)
      .chain()
      .filter((row) => row.party.participantType = 'CONTESTANT')
      .map((row) =>
          Math.min(config.contestHistogram.maxBuckets-1,
            Math.max(0,
              Math.floor(row.points / bucketSize))))
      .value();
    const pointDistribution = _.countBy(points, _.identity);
    console.log(`Contest ${contest.id}, participants: ${result.rows.length}, active buckets: ${_.keys(pointDistribution).length}`);
    const scores = {
      maxPoints: maxPoints,
      bucketSize: bucketSize,
      pointDistribution: pointDistribution
    };
    details.scores = scores;
  }

  return details;
}

// -----------------------------------------------------------------------------
// ---- Problems
// -----------------------------------------------------------------------------

async function loadAllProblems() {
  const response = await http.get('https://codeforces.com/api/problemset.problems');
  const problems = response.data.result.problems;
  console.log(`Fetched # problems: ${problems.length}`);

  const newProblems = await async.mapLimit(
      problems,
      config.concurrency.maxProblemsLoadingInParallel,
      loadProblem);

  const processed = newProblems.reduce(ret.combine, ret.nothing);
  functions.logger.log(`Problems fetched: ${problems.length}, loaded: ${ret.toString(processed)}`);
  return processed;
}

async function loadProblem(problem) {
  try {
    const problemId = problem.contestId + problem.index;
    const problemRef = db.collection('problems').doc(problemId);
    if ((await problemRef.get()).exists) {
      return ret.nothing;
    }

    console.log(`Found new problem: ${problemId}`);
    await problemRef.set(problem);
    console.log(`Finished processing new problem: ${problemId}`);
    return ret.result;

  } catch (error) {
    functions.logger.error(`Error fetching problem: ${problem.id}: ${error}`);
    return ret.error(problem.id);
  }
}

// -----------------------------------------------------------------------------
// ---- Users
// -----------------------------------------------------------------------------

async function loadUser(user) {
  const userRef = db.collection('users').doc(user);
  const userData = await userRef.get();

  var from = 1 + (userData.exists) ? 1+userData.data().meta.numProcessed : 0;
  console.log(`Fetching user ${user} starting from submission ${from}.`);

  const url = `https://codeforces.com/api/user.status?handle=${user}&from=${first}`;
  const response = await http.get(url);
  const data = response.data.result;

  const newSubmissions = data.length;
  await userRef.set({
    meta: {
      numProcessed: FieldValue.increment(newSubmissions),
      timesFetched: FieldValue.increment(1)
    }
  });

  return {
    user: user,
    newSubmissions: newSubmissions
  };
}
