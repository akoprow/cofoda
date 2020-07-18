import 'package:cofoda/model/problem.dart';

class Submission {
  final String problemId;
  final bool solved;

  Submission({this.problemId, this.solved});

  factory Submission.fromJson(Map<String, dynamic> json) {
    final problem = Problem.fromJson(json['problem'] as Map<String, dynamic>);
    return Submission(problemId: problem.id, solved: json['verdict'] == 'OK');
  }
}

enum ProblemStatus { solved, tried, untried }

class AllSubmissions {
  // Map from problem ID (i.e. 1385E) to a set of submissions for that problem.
  final Map<String, Set<Submission>> _submissions;

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

  factory AllSubmissions.fromJson(List<dynamic> json) {
    final submissions = json.map((dynamic json) => Submission.fromJson(json as Map<String, dynamic>));
    final problemIds = submissions.map((submission) => submission.problemId).toSet();
    return AllSubmissions({
      for (var problemId in problemIds)
        problemId: submissions.where((submission) => submission.problemId == problemId).toSet()
    });
  }
}
