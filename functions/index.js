'use strict';

const _ = require('lodash');
const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");

admin.initializeApp();
const db = admin.firestore();

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
.onCreate(async (change, context) => {
  await loadContestDetails(context.params.contestId);
});

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
  if (contest.phase !== 'FINISHED' || contest.type !== 'CF') {
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

async function loadContestDetails(contestId) {
  console.log(`Fetching details of contest: ${contestId}`);
  const response = await axios.get('https://codeforces.com/api/contest.standings'
    + `?contestId=${contestId}&showUnofficial=false`);
  const result = response.data.result;

  const contestDetailsRef = db.collection('contests').doc(contestId)
    .collection('details').doc('scores');

  const maxPoints = _.sumBy(result.problems, (problem) => problem.points);
  const points = _(result.rows)
    .chain()
    .filter((row) => row.party.participantType = 'CONTESTANT')
    .map((row) => row.points)
    .value();
  const pointDistribution = _.countBy(points, _.identity);
  console.log(`Contest ${contestId}: participants: ${points.length}, diff scores: ${_.keys(pointDistribution).length}`);

  await contestDetailsRef.set({
    maxPoints: maxPoints,
    pointDistribution: pointDistribution
  });
}
