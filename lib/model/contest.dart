import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/problemList.dart';

class Contest implements Comparable<Contest> {
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
        problems: problemList.problems
            .where((problem) => problem.contestId == id)
            .toList());
  }

  factory Contest.fromFire(QueryDocumentSnapshot fire) {
    final data = fire.data();
    final id = data['id'] as int;
    final details = data['details'] as Map<String, dynamic>;
    final problems = details['problems'] as List<dynamic>;

    return Contest(
        id: id,
        name: data['name'] as String,
        type: data['type'] as String,
        phase: data['phase'] as String,
        problems: problems
            .map((dynamic p) => Problem.fromJson(p as Map<String, dynamic>))
            .toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(Contest other) => id?.compareTo(other?.id ?? -1) ?? 1;
}
