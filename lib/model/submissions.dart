import 'dart:math';

import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problem.dart';

import 'contest.dart';

// BEWARE: order matters as we pick the last that matches.
enum ProblemStatus {
  untried,
  toUpSolve,
  tried,
  solvedElsewhere,
  solvedPractice,
  solvedVirtual,
  solvedLive
}

final solvedStatuses = {
  ProblemStatus.solvedLive,
  ProblemStatus.solvedVirtual,
  ProblemStatus.solvedPractice
};

ProblemStatus _betterStatus(ProblemStatus s1, ProblemStatus s2) =>
    ProblemStatus.values[max(s1.index, s2.index)];

class Submission {
  final String problemId;
  final String contestId;
  final DateTime time;
  final ProblemStatus status;

  Submission({this.problemId, this.time, this.status, this.contestId});

  factory Submission.fromJson(Map<String, dynamic> json) {
    final problem = Problem.fromJson(json['problem'] as Map<String, dynamic>);
    final verdict = json['verdict'] as String;
    final author = json['author'] as Map<String, dynamic>;
    final participantType = author['participantType'] as String;

    return Submission(
        problemId: problem.id,
        time: DateTime.fromMillisecondsSinceEpoch(
            1000 * (json['creationTimeSeconds'] as int)),
        status: _parseProblemStatus(verdict, participantType));
  }

  factory Submission.fromFire(MapEntry<String, dynamic> entry) {
    final data = entry.value as Map<String, dynamic>;
    final contestId = data['contestId'] as int;
    final problemIndex = data['problemIndex'] as String;
    final verdict = data['verdict'] as String;
    final participantType = data['participantType'] as String;
    return Submission(
        contestId: contestId.toString(),
        problemId: contestId.toString() + problemIndex,
        time: DateTime.fromMillisecondsSinceEpoch(
            1000 * (data['creationTimeSeconds'] as int)),
        status: _parseProblemStatus(verdict, participantType));
  }

  static ProblemStatus _parseProblemStatus(
      String verdict, String participantType) {
    if (verdict != 'OK') {
      return ProblemStatus.tried;
    } else {
      switch (participantType) {
        case 'CONTESTANT':
          return ProblemStatus.solvedLive;
        case 'VIRTUAL':
          return ProblemStatus.solvedVirtual;
        case 'PRACTICE':
        case 'OUT_OF_COMPETITION':
          return ProblemStatus.solvedPractice;
        default:
          throw 'Unknown participant type: $participantType';
      }
    }
  }
}

class AllUserSubmissions {
  // Map from problem *name* to a set of submissions for that problem.
  final Map<String, List<Submission>> _submissions;

  AllUserSubmissions(this._submissions);

  List<Problem> getSubmittedProblems(ContestList contests) =>
      _submissions.keys
      .map((problemName) => contests.getProblemByName(problemName))
      .toList();

  List<Submission> submissionsForProblem(Problem problem) =>
      _submissions.containsKey(problem.name) ? _submissions[problem.name] : [];

  ProblemStatus statusOfProblem(Contest contest, Problem problem,
      {int ratingLimit}) {
    var result = (ratingLimit != null &&
        problem.rating != null &&
        problem.rating <= ratingLimit)
        ? ProblemStatus.toUpSolve
        : ProblemStatus.untried;
    for (final submission in submissionsForProblem(problem)) {
      final submissionStatus =
      (solvedStatuses.contains(submission.status) &&
          contest.id != submission.contestId) ?
      ProblemStatus.solvedElsewhere : submission.status;
      result = _betterStatus(result, submissionStatus);
    }
    return result;
  }

  Submission solvedWith(Problem problem) {
    for (final submission in submissionsForProblem(problem)) {
      if (solvedStatuses.contains(submission.status)) return submission;
    }
    return null;
  }

  factory AllUserSubmissions.empty() => AllUserSubmissions({});

  factory AllUserSubmissions.fromJson(List<dynamic> json) {
    final submissions = json.map((dynamic json) =>
        Submission.fromJson(json as Map<String, dynamic>));
    final submittedProblems = submissions.map((submission) =>
    submission.problemId).toSet();
    throw UnimplementedError();
  }

  static AllUserSubmissions fromFire(ContestList contests,
      Map<String, dynamic> json) {
    if (json == null) {
      return AllUserSubmissions.empty();
    }
    final jsonSubmissions = json['submissions'] as Map<String, dynamic>;
    final List<Submission> submissions = jsonSubmissions.entries
        .map((entry) => Submission.fromFire(entry))
        .toList();

    final submissionsByProblemName = <String, List<Submission>>{};
    for (final submission in submissions) {
      final Problem problem = contests.getProblem(
          contestId: submission.contestId, problemId: submission.problemId);
      if (problem == null) continue;
      submissionsByProblemName.putIfAbsent(problem.name, () => [])
        ..add(submission);
    }

    return AllUserSubmissions(submissionsByProblemName);
  }
}
