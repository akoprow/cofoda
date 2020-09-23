import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cofoda/codeforcesAPI.dart';
import 'package:flutter/material.dart';

enum GroupSolvedProblemsBy { day, week, month, year }

class UserProblemsOverTimeChart extends StatelessWidget {
  final List<String> users;
  final Data data;

  const UserProblemsOverTimeChart({Key key, this.users, this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userData = _generateUserSeries(users[0], charts.MaterialPalette.blue.shadeDefault);
    final vsUserData = users[1] == null ? null : _generateUserSeries(users[1], charts.MaterialPalette.red.shadeDefault);
    final chart = charts.TimeSeriesChart([userData, vsUserData].where((element) => element != null).toList());
    return Card(child: Column(children: [ListTile(title: Text('Solved problems')), Expanded(child: chart)]));
  }

  charts.Series<SolvedProblems, DateTime> _generateUserSeries(String user, charts.Color color) {
    final Map<DateTime, int> solvedByDay = _getUserSolvedByDay(user);
    return charts.Series<SolvedProblems, DateTime>(
        id: user,
        colorFn: (_, __) => color,
        domainFn: (SolvedProblems problems, _) => problems.date,
        measureFn: (SolvedProblems problems, _) => problems.numSolved,
        data: solvedByDay.entries.map((entry) => SolvedProblems(entry.key, entry.value)).toList());
  }

  Map<DateTime, int> _getUserSolvedByDay(String user,
      {bool acumulative = true, GroupSolvedProblemsBy groupBy = GroupSolvedProblemsBy.day}) {
    final submissions = data.userSubmissions[user];
    final solvedAt = submissions.submittedProblems
        .map((problem) => submissions.solvedWith(problem))
        .where((solution) => solution != null)
        .map((solution) => solution.time)
        .toList();
    solvedAt.sort();

    final solved = <DateTime, int>{};
    var solvedNum = 0;
    for (final solutionTime in solvedAt) {
      final day = _roundDate(solutionTime, groupBy);
      solved[day] = (acumulative) ? ++solvedNum : 1 + ((solved[day] != null) ? solved[day] : 0);
    }
    return solved;
  }

  DateTime _roundDate(DateTime solutionTime, GroupSolvedProblemsBy groupBy) {
    switch (groupBy) {
      case GroupSolvedProblemsBy.day:
        return DateTime(solutionTime.year, solutionTime.month, solutionTime.day);
      case GroupSolvedProblemsBy.month:
        return DateTime(solutionTime.year, solutionTime.month);
      case GroupSolvedProblemsBy.year:
        return DateTime(solutionTime.year);
      default:
        throw 'Unknown grouping: $groupBy';
    }
  }
}

class SolvedProblems {
  final DateTime date;
  final int numSolved;

  SolvedProblems(this.date, this.numSolved);
}
