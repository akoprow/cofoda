import 'package:cofoda/model/contest.dart';

class ContestList {
  final List<Contest> contests;

  ContestList({this.contests});

  factory ContestList.fromJson(List<dynamic> json) =>
      ContestList(contests: json.map((json) => Contest.fromJson(json as Map<String, dynamic>)).toList());
}
