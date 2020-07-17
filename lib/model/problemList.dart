import 'package:cofoda/model/problem.dart';

class ProblemList {
  final List<Problem> problems;

  ProblemList({this.problems});

  factory ProblemList.fromJson(List<dynamic> json) {
    final problems = json.map((dynamic json) => Problem.fromJson(json as Map<String, dynamic>)).toList();
    return ProblemList(problems: problems);
  }
}
