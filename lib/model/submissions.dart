import 'dart:math';

import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problem.dart';

// BEWARE: order matters as we pick the last that matches.
enum ProblemStatus { untried, toUpSolve, tried, solvedPractice, solvedVirtual, solvedLive }

final solvedStatuses = {ProblemStatus.solvedLive, ProblemStatus.solvedVirtual, ProblemStatus.solvedPractice};

ProblemStatus _betterStatus(ProblemStatus s1, ProblemStatus s2) => ProblemStatus.values[max(s1.index, s2.index)];

class Submission {
  final String problemId;
  final DateTime time;
  final ProblemStatus status;

  Submission({this.problemId, this.time, this.status});

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
  // Map from problem ID (i.e. 1385E) to a set of submissions for that problem.
  final Map<String, List<Submission>> _submissions;

  AllUserSubmissions(this._submissions);

  List<Problem> getSubmittedProblems(ContestList contests) => _submissions.keys
      .map((problemId) => contests.getProblemById(problemId))
      .toList();

  List<Submission> submissionsForProblem(Problem problem) =>
      _submissions.containsKey(problem.id) ? _submissions[problem.id] : [];

  ProblemStatus statusOfProblem(Problem problem, {int ratingLimit}) {
    var result = (ratingLimit != null &&
            problem.rating != null &&
            problem.rating <= ratingLimit)
        ? ProblemStatus.toUpSolve
        : ProblemStatus.untried;
    for (final submission in submissionsForProblem(problem)) {
      result = _betterStatus(result, submission.status);
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
    return AllUserSubmissions({
      for (var problem in submittedProblems)
        problem: submissions.where((submission) =>
        submission.problemId == problem).toList()
    });
  }

  static AllUserSubmissions fromFire(Map<String, dynamic> json) {
    if (json == null) {
      return AllUserSubmissions.empty();
    }
    final jsonSubmissions = json['submissions'] as Map<String, dynamic>;
    final List<Submission> submissions = jsonSubmissions.entries
        .map((entry) => Submission.fromFire(entry))
        .toList();
    final submittedProblems =
        submissions.map((submission) => submission.problemId).toSet();
    return AllUserSubmissions({
      for (var problem in submittedProblems)
        problem: submissions
            .where((submission) => submission.problemId == problem)
            .toList()
    });
  }
}
