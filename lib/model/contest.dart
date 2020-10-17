import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/problemList.dart';

class ContestResults {
  final Map<int, int> pointDistribution;
  final int maxPoints;
  final int bucketSize;

  ContestResults({this.pointDistribution, this.maxPoints, this.bucketSize});

  factory ContestResults.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['pointDistribution'] as Map<String, dynamic>;
    final points = pointsJson.map(
        (String key, dynamic value) => MapEntry(int.parse(key), value as int));
    return ContestResults(
        pointDistribution: points,
        maxPoints: json['maxPoints'] as int,
        bucketSize: json['bucketSize'] as int);
  }
}

class Contest implements Comparable<Contest> {
  final int id;
  final String name, type, phase;
  final List<Problem> problems;
  final ContestResults results;

  Contest(
      {this.id, this.name, this.type, this.phase, this.problems, this.results});

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
    final problemsJson = details['problems'] as List<dynamic>;
    final problems = problemsJson
        .map((dynamic p) => Problem.fromJson(p as Map<String, dynamic>))
        .toList();
    final scores = (details.containsKey('scores')) ? ContestResults.fromJson(
        details['scores'] as Map<String, dynamic>) : null;

    return Contest(
        id: id,
        name: data['name'] as String,
        type: data['type'] as String,
        phase: data['phase'] as String,
        results: scores,
        problems: problems);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Contest && runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  int compareTo(Contest other) => id?.compareTo(other?.id ?? -1) ?? 1;
}
