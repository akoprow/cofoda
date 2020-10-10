'use strict';

const _ = require('lodash');
const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");
const rateLimit = require('axios-rate-limit');

// -----------------------------------------------------------------------------
// ---- Constants
// -----------------------------------------------------------------------------
const contestScoreHistogramBucketsNum = 50;
const codeforces = {
  concurrency: {
    maxProblemsLoadingInParallel: 10,
    maxContestsLoadingInParallel: 10
  },
  maxContestsInOneBatch: 100,
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

exports.loadData = functions.runWith({timeoutSeconds: 540}).https
.onRequest(async (req, res) => {
  const newContests = await loadAllContests();
  const newProblems = await loadAllProblems();
  res.json({
    newContests: ret.toString(newContests),
    newProblems: ret.toString(newProblems)
  });
});

// -----------------------------------------------------------------------------
// ---- Contests
// -----------------------------------------------------------------------------

async function loadAllContests() {
  const response = await http.get('https://codeforces.com/api/contest.list?gym=false');
  const contests = response.data.result;
  const toLoad = await async.filterLimit(
      contests, codeforces.concurrency.maxContestsLoadingInParallel, needToLoadContest);

  console.log(`Fetched contests: ${contests.length}, need loading: ${toLoad.length}`);
  const newContests = await async.mapLimit(
      _.take(toLoad, codeforces.maxContestsInOneBatch),
      codeforces.concurrency.maxContestsLoadingInParallel,
      loadContest);

  const processed = newContests.reduce(ret.combine, ret.nothing);
  functions.logger.log(`Contests fetched: ${contests.length}, need loading: ${toLoad.length}, loaded: ${ret.toString(processed)}`);
  return processed;
}

async function needToLoadContest(contest) {
  try {
    if (contest.phase !== 'FINISHED') return false;
    if (codeforces.forbiddenContests.includes(contest.id)) return false;

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
    const bucketSize = maxPoints / contestScoreHistogramBucketsNum;
    const points = _(result.rows)
      .chain()
      .filter((row) => row.party.participantType = 'CONTESTANT')
      .map((row) => Math.floor(row.points / bucketSize))
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
      codeforces.concurrency.maxProblemsLoadingInParallel,
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
