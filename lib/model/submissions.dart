import 'package:cofoda/model/problem.dart';

class Submission {
  final Problem problem;
  final bool solved;

  Submission({this.problem, this.solved});

  factory Submission.fromJson(Map<String, dynamic> json) {
    final problem = Problem.fromJson(json['problem'] as Map<String, dynamic>);
    return Submission(problem: problem, solved: json['verdict'] == 'OK');
  }
}

enum ProblemStatus { solved, tried, untried }

class AllSubmissions {
  // Map from problem ID (i.e. 1385E) to a set of submissions for that problem.
  final Map<Problem, Set<Submission>> _submissions;

  AllSubmissions(this._submissions);

  ProblemStatus getProblemStatus(Problem problem) {
    if (_submissions.containsKey(problem.id)) {
      return _submissions[problem.id].any((submission) => submission.solved)
          ? ProblemStatus.solved
          : ProblemStatus.tried;
    } else {
      return ProblemStatus.untried;
    }
  }

  List<Problem> get submittedProblems => _submissions.keys.toList();

  factory AllSubmissions.empty() => AllSubmissions({});

  factory AllSubmissions.fromJson(List<dynamic> json) {
    final submissions = json.map((dynamic json) => Submission.fromJson(json as Map<String, dynamic>));
    final submittedProblems = submissions.map((submission) => submission.problem).toSet();
    return AllSubmissions({
      for (var problem in submittedProblems)
        problem: submissions.where((submission) => submission.problem == problem).toSet()
    });
  }
}
