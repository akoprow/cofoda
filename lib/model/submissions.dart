import 'dart:math';

import 'package:cofoda/model/problem.dart';

// BEWARE: order matters as we pick the last that matches.
enum ProblemStatus { untried, toUpSolve, tried, solvedPractice, solvedVirtual, solvedLive }

final solvedStatuses = {ProblemStatus.solvedLive, ProblemStatus.solvedVirtual, ProblemStatus.solvedPractice};

ProblemStatus _betterStatus(ProblemStatus s1, ProblemStatus s2) => ProblemStatus.values[max(s1.index, s2.index)];

class Submission {
  final Problem problem;
  final ProblemStatus status;

  Submission({this.problem, this.status});

  factory Submission.fromJson(Map<String, dynamic> json) {
    final problem = Problem.fromJson(json['problem'] as Map<String, dynamic>);
    return Submission(problem: problem, status: _parseProblemStatus(json));
  }

  static ProblemStatus _parseProblemStatus(Map<String, dynamic> json) {
    if (json['verdict'] != 'OK') {
      return ProblemStatus.tried;
    } else {
      final author = json['author'] as Map<String, dynamic>;
      final participantType = author['participantType'] as String;
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
  final Map<Problem, List<Submission>> _submissions;

  AllUserSubmissions(this._submissions);

  List<Problem> get submittedProblems => _submissions.keys.toList();

  List<Submission> submissionsForProblem(Problem problem) =>
      _submissions.containsKey(problem) ? _submissions[problem] : [];

  ProblemStatus statusOfProblem(Problem problem, {int ratingLimit}) {
    var result = (ratingLimit != null && problem.rating != null && problem.rating <= ratingLimit)
        ? ProblemStatus.toUpSolve
        : ProblemStatus.untried;
    for (final submission in submissionsForProblem(problem)) {
      result = _betterStatus(result, submission.status);
    }
    return result;
  }

  factory AllUserSubmissions.empty() => AllUserSubmissions({});

  factory AllUserSubmissions.fromJson(List<dynamic> json) {
    final submissions = json.map((dynamic json) => Submission.fromJson(json as Map<String, dynamic>));
    final submittedProblems = submissions.map((submission) => submission.problem).toSet();
    return AllUserSubmissions({
      for (var problem in submittedProblems)
        problem: submissions.where((submission) => submission.problem == problem).toList()
    });
  }
}
