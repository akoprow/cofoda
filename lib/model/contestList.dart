import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';

class ContestList {
  final List<Contest> contests;

  ContestList({this.contests});

  factory ContestList.fromJson(List<dynamic> json, List<Problem> problems) => ContestList(
      contests: json.map((dynamic json) => Contest.fromJson(json as Map<String, dynamic>, problems)).toList());
}
