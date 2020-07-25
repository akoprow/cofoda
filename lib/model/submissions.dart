import 'dart:ui';

import 'package:cofoda/model/problem.dart';
import 'package:flutter/material.dart';

enum ProblemStatus { solved, tried, untried }

ProblemStatus _betterStatus(ProblemStatus s1, ProblemStatus s2) {
  if (s1 == ProblemStatus.solved) {
    return s1;
  } else if (s2 == ProblemStatus.solved) {
    return s2;
  } else if (s1 == ProblemStatus.tried || s2 == ProblemStatus.tried) {
    return ProblemStatus.tried;
  } else {
    return ProblemStatus.untried;
  }
}

Color problemStatusToColor(ProblemStatus status) {
  const int colorIntensity = 100;
  switch (status) {
    case ProblemStatus.solved:
      return Colors.green[colorIntensity];
    case ProblemStatus.tried:
      return Colors.yellow[colorIntensity];
    default:
      return Colors.white;
  }
}

class Submission {
  final Problem problem;
  final bool solved;

  Submission({this.problem, this.solved});

  ProblemStatus get status => solved ? ProblemStatus.solved : ProblemStatus.tried;

  factory Submission.fromJson(Map<String, dynamic> json) {
    final problem = Problem.fromJson(json['problem'] as Map<String, dynamic>);
    return Submission(problem: problem, solved: json['verdict'] == 'OK');
  }
}

class AllSubmissions {
  // Map from problem ID (i.e. 1385E) to a set of submissions for that problem.
  final Map<Problem, List<Submission>> _submissions;

  AllSubmissions(this._submissions);

  List<Problem> get submittedProblems => _submissions.keys.toList();

  List<Submission> submissionsForProblem(Problem problem) =>
      _submissions.containsKey(problem) ? _submissions[problem] : [];

  ProblemStatus statusOfProblem(Problem problem) {
    var result = ProblemStatus.untried;
    for (final submission in submissionsForProblem(problem)) {
      result = _betterStatus(result, submission.status);
    }
    return result;
  }

  factory AllSubmissions.empty() => AllSubmissions({});

  factory AllSubmissions.fromJson(List<dynamic> json) {
    final submissions = json.map((dynamic json) => Submission.fromJson(json as Map<String, dynamic>));
    final submittedProblems = submissions.map((submission) => submission.problem).toSet();
    return AllSubmissions({
      for (var problem in submittedProblems)
        problem: submissions.where((submission) => submission.problem == problem).toList()
    });
  }
}
