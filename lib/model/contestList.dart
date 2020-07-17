import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problemList.dart';

class ContestList {
  final List<Contest> contests;

  ContestList({this.contests});

  factory ContestList.fromJson(List<dynamic> json, ProblemList problems) {
    final contests = json
        .map((dynamic json) => Contest.fromJson(json as Map<String, dynamic>, problems))
        .where((contest) => contest.phase == 'FINISHED')
        .toList();
    return ContestList(contests: contests);
  }
}
