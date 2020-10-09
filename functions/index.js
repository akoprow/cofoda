'use strict';

const _ = require('lodash');
const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");

admin.initializeApp();
const db = admin.firestore();

const contestScoreHistogramBucketsNum = 50;
const limitContests = 20;
const limitProblems = 5;

const concurrencyLimits = {
  maxProblemsLoadingInParallel: 10,
  maxContestsLoadingInParallel: 10
}

exports.loadData = functions.runWith({timeoutSeconds: 540}).https
.onRequest(async (req, res) => {
  const newContests = await loadAllContests();
  const newProblems = await loadAllProblems();
  res.json({newContests: newContests, newProblems: newProblems});
});

exports.loadContestDetails = functions.firestore.document('contests/{contestId}')
  .onCreate(async (snap, context) => await loadContestDetails(snap));

async function loadAllContests() {
  const response = await axios.get('https://codeforces.com/api/contest.list?gym=false');
  const contests = response.data.result.slice(0, limitContests);
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
  console.log(`Finished processing new contest: ${contest.id}`);
  return 1;
}

async function loadAllProblems() {
  const response = await axios.get('https://codeforces.com/api/problemset.problems');
  const problems = response.data.result.problems.slice(0, limitProblems);
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

// TODO: bundle into histogram buckets.
async function loadContestDetails(snap) {
  const contest = snap.data();
  if (contest.type !== 'CF') return

  console.log(`Fetching details of contest: ${contest.id}`);
  const response = await axios.get('https://codeforces.com/api/contest.standings'
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

  await snap.ref.update({
    maxPoints: maxPoints,
    bucketSize: bucketSize,
    pointDistribution: pointDistribution
  });
}
