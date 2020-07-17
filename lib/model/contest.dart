import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/problemList.dart';

class Contest {
  final int id;
  final String name, type, phase;
  final List<Problem> problems;

  Contest({this.id, this.name, this.type, this.phase, this.problems});

  factory Contest.fromJson(Map<String, dynamic> json, ProblemList problemList) {
    final id = json['id'] as int;
    return Contest(
        id: id,
        name: json['name'] as String,
        type: json['type'] as String,
        phase: json['phase'] as String,
        problems: problemList.problems.where((problem) => problem.contestId == id).toList());
  }
}
