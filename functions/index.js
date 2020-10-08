'use strict';

const functions = require('firebase-functions');
const axios = require('axios');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.loadContests = functions.https.onRequest(async (req, res) => {
    const response = await axios.get('https://codeforces.com/api/contest.list?gym=false');
    console.log(`Fetched # contests: ${response.data.result.length}`);
    await Promise.all(response.data.result.map((item, index) => loadContest(item)));
    res.json({result: 'OK'});
});

function loadContest(contest) {
    console.log(`Processing contest: ${contest.id}`);
    return db.collection('contests').doc(contest.id.toString()).set({
        name: contest.name
    });
}
