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
const concurrencyLimits = {
  maxProblemsLoadingInParallel: 10,
  maxContestsLoadingInParallel: 10
}

// -----------------------------------------------------------------------------
// ---- Globals
// -----------------------------------------------------------------------------

admin.initializeApp();
const db = admin.firestore();
const http = rateLimit(axios.create(), { maxRPS: 3 })

// -----------------------------------------------------------------------------
// ---- Entry points
// -----------------------------------------------------------------------------

exports.loadData = functions.runWith({timeoutSeconds: 540}).https
.onRequest(async (req, res) => {
  const newContests = await loadAllContests();
  const newProblems = await loadAllProblems();
  res.json({newContests: newContests, newProblems: newProblems});
});

// -----------------------------------------------------------------------------
// ---- Contests
// -----------------------------------------------------------------------------

async function loadAllContests() {
  const response = await http.get('https://codeforces.com/api/contest.list?gym=false');
  const contests = response.data.result;
  functions.logger.log(`Fetched contests #: ${contests.length}`);

  const newContests = await async.mapLimit(contests, concurrencyLimits.maxContestsLoadingInParallel, loadContest);
  const numNewContests = newContests.reduce((a, b) => a + b, 0);
  functions.logger.log(`Processed new contests #: ${numNewContests}`);
  return numNewContests;
}

async function loadContest(contest) {
  if (contest.phase !== 'FINISHED') {
    return 0;
  }
  const contestRef = db.collection('contests').doc(contest.id.toString())
  if ((await contestRef.get()).exists) {
    return 0;
  }

  console.log(`Found new contest: ${contest.id}`);
  await contestRef.set(contest);
  if (contest.type === 'CF') {
    await loadContestDetails(contest, contestRef);
  }
  console.log(`Finished processing new contest: ${contest.id}`);
  return 1;
}

async function loadContestDetails(contest, contestRef) {
  console.log(`Fetching details of contest: ${contest.id}`);
  const response = await http.get('https://codeforces.com/api/contest.standings'
    + `?contestId=${contest.id}&showUnofficial=false`);
  const result = response.data.result;

  const maxPoints = _.sumBy(result.problems, (problem) => problem.points);
  const bucketSize = maxPoints / contestScoreHistogramBucketsNum;
  const points = _(result.rows)
    .chain()
    .filter((row) => row.party.participantType = 'CONTESTANT')
    .map((row) => Math.floor(row.points / bucketSize))
    .value();
  const pointDistribution = _.countBy(points, _.identity);
  console.log(`Contest ${contest.id}, participants: ${result.rows.length}, active buckets: ${_.keys(pointDistribution).length}`);

  await contestRef.update({
    maxPoints: maxPoints,
    bucketSize: bucketSize,
    pointDistribution: pointDistribution
  });
}

// -----------------------------------------------------------------------------
// ---- Problems
// -----------------------------------------------------------------------------

async function loadAllProblems() {
  const response = await http.get('https://codeforces.com/api/problemset.problems');
  const problems = response.data.result.problems;
  functions.logger.log(`Fetched # problems: ${problems.length}`);

  const newProblems = await async.mapLimit(problems, concurrencyLimits.maxProblemsLoadingInParallel, loadProblem);
  const numNewProblems = newProblems.reduce((a, b) => a + b, 0);
  functions.logger.log(`Processed new problems #: ${numNewProblems}`);
  return numNewProblems;
}

async function loadProblem(problem) {
  const problemId = problem.contestId + problem.index;
  const problemRef = db.collection('problems').doc(problemId);
  if ((await problemRef.get()).exists) {
    return 0;
  }

  console.log(`Found new problem: ${problemId}`);
  await problemRef.set(problem);
  console.log(`Finished processing new problem: ${problemId}`);
  return 1;
}
