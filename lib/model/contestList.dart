import 'package:dashforces/model/contest.dart';
import 'package:dashforces/model/problem.dart';
import 'package:dashforces/model/problemList.dart';

class ContestList {
  // contest id -> contest
  final Map<String, Contest> _contests;

  // problem name -> problem
  final Map<String, Problem> _problemsByName;

  ContestList(List<Contest> contestList)
      : _contests = {for (final contest in contestList) contest.id: contest},
        _problemsByName = _getProblemsByName(contestList);

  factory ContestList.empty() => ContestList([]);

  Problem getProblemByName(String problemName) => _problemsByName[problemName];

  Problem getProblem({String contestId, String problemId}) {
    final contest = _contests[contestId];
    if (contest == null) {
      print('Unknown contest: $contestId');
      return null;
    }
    final problem =
        contest.problems.where((problem) => problem.id == problemId).first;
    if (problem == null) {
      print('Unknown problem: $problemId in contest $contestId');
      return null;
    }
    return problem;
  }

  List<Contest> get contests => _contests.values.toList();

  factory ContestList.fromJson(List<dynamic> json, ProblemList problems) {
    final contests = json
        .map((dynamic json) =>
            Contest.fromJson(json as Map<String, dynamic>, problems))
        .where((contest) => contest.phase == 'FINISHED')
        .toList();
    return ContestList(contests);
  }

  Contest getContestById(String contestId) => _contests[contestId];

  static Map<String, Problem> _getProblemsByName(List<Contest> contestList) {
    final res = <String, Problem>{};
    for (final contest in contestList) {
      for (final problem in contest.problems) {
        res[problem.name] = problem;
      }
    }
    return res;
  }
}
