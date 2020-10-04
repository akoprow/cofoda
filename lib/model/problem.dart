import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:url_launcher/url_launcher.dart';

class Problem implements Comparable<Problem> {
  final int contestId, rating;
  final String index, name, type;
  final List<String> tags;

  Problem({this.contestId, this.index, this.name, this.type, this.rating, this.tags});

  String get id => '$contestId$index';

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
      contestId: json['contestId'] as int,
      index: json['index'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      rating: json.containsKey('rating') ? json['rating'] as int : null,
      tags: (json['tags'] as List<dynamic>).cast<String>());

  Contest getContest(Data data) => data.contestList.getContestById(contestId);

  @override
  int compareTo(Problem other) => name.compareTo(other.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Problem && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  Future<void> open() =>
      launch('https://codeforces.com/contest/$contestId/problem/$index');
}
