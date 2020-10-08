'use strict';

const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");

admin.initializeApp();
const db = admin.firestore();

const concurrencyLimits = {
  maxProblemsLoadingInParallel: 10,
  maxContestsLoadingInParallel: 10
}

exports.loadData = functions.runWith({timeoutSeconds: 540}).https.onRequest(async (req, res) => {
  await loadAllContests();
  await loadAllProblems();
  res.json({result: 'OK'});
});

async function loadAllContests() {
  const response = await axios.get('https://codeforces.com/api/contest.list?gym=false');
  const contests = response.data.result.splice(0, 10);
  functions.logger.log(`Fetched contests #: ${contests.length}`);

  const newContests = await async.mapLimit(contests, concurrencyLimits.maxContestsLoadingInParallel, loadContest);
  const numNewContests = newContests.reduce((a, b) => a + b, 0);
  functions.logger.log(`Processed new contests #: ${numNewContests}`);
}

async function loadContest(contest) {
  const contestRef = db.collection('contests').doc(contest.id.toString())
  if ((await contestRef.get()).exists) {
    return 0;
  }

  console.log(`Found new contest: ${contest.id}`);
  await contestRef.set({
    name: contest.name
  });
  console.log(`Finished processing new contest: ${contest.id}`);
  return 1;
}

async function loadAllProblems() {
  const response = await axios.get('https://codeforces.com/api/problemset.problems');
  const problems = response.data.result.problems.splice(0, 10);
  functions.logger.log(`Fetched # problems: ${problems.length}`);

  const newProblems = await async.mapLimit(problems, concurrencyLimits.maxProblemsLoadingInParallel, loadProblem);
  const numNewProblems = newProblems.reduce((a, b) => a + b, 0);
  functions.logger.log(`Processed new problems #: ${numNewProblems}`);
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
