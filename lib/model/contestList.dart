import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problemList.dart';

class ContestList {
  final Map<int, Contest> _contests;

  ContestList(Iterable<Contest> contestList) : _contests = {for (var contest in contestList) contest.id: contest};

  List<Contest> get allContests => _contests.values.toList();

  factory ContestList.fromJson(List<dynamic> json, ProblemList problems) {
    final contests = json
        .map((dynamic json) => Contest.fromJson(json as Map<String, dynamic>, problems))
        .where((contest) => contest.phase == 'FINISHED')
        .toList();
    return ContestList(contests);
  }

  Contest getContestById(int contestId) => _contests[contestId];
}
