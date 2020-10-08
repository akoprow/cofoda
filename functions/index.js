'use strict';

const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');
const async = require("async");

admin.initializeApp();
const db = admin.firestore();

exports.loadData = functions.runWith({timeoutSeconds: 540}).https.onRequest(async (req, res) => {
  //await loadAllContests();
  await loadAllProblems();
  es.json({result: 'OK'});
});

async function loadAllContests() {
  const response = await axios.get('https://codeforces.com/api/contest.list?gym=false');

  console.log(`Fetched contests #: ${response.data.result.length}`);
  const newContests = await async.map(response.data.result, (contest) => loadContest(contest));
  const numNewContests = newContests.reduce((a, b) => a + b, 0);
  console.log(`Processed new contests #: ${numNewContests}`);
}

async function loadContest(contest) {
  const contestRef = db.collection('contests').doc(contest.id.toString())
  if (!contestRef.exists) {
    console.log(`Found new contest: ${contest.id}`);
    await contestRef.set({
      name: contest.name
    });
    console.log(`Finished processing new contest: ${contest.id}`);
  }
}

async function loadAllProblems() {
  const response = await axios.get('https://codeforces.com/api/problemset.problems');
  console.log(`Fetched # problems: ${response.data.result.problems.length}`);
  await async.each(response.data.result.problems, (problem) => loadProblem(problem));
}

async function loadProblem(problem) {
  const problemId = problem.contestId + problem.index;
  const problemRef = db.collection('problems').doc(problemId);
  if (!problemRef.exists) {
    console.log(`Found new problem: ${problemId}`);
    await problemRef.set(problem);
    console.log(`Finished processing new problem: ${problemId}`);
  }
}
