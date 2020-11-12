import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/data/userData.dart';
import 'package:dashforces/model/contestList.dart';
import 'package:dashforces/ui/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum GroupSolvedProblemsBy { day, week, month, year }

class UserProblemsOverTimeChart extends StatefulWidget {
  const UserProblemsOverTimeChart({Key key}) : super(key: key);

  @override
  State<UserProblemsOverTimeChart> createState() =>
      UserProblemsOverTimeChartState();
}

class UserProblemsOverTimeChartState extends State<UserProblemsOverTimeChart> {
  bool cumulative = true;
  GroupSolvedProblemsBy groupBy = GroupSolvedProblemsBy.day;

  UserProblemsOverTimeChartState();

  @override
  Widget build(BuildContext ctx) =>
      withUsers((userData) => _show(ctx, userData));

  Widget _show(BuildContext ctx, BothUsersData users) {
    if (!users.user.isPresent()) {
      return Text(
          "Please provide one or two users via 'users' URL query parameter.");
    }

    final user = users.user;
    final vsUser = users.vsUser;
    final userData = _generateUserSeries(ctx, user);
    final vsUserData =
        vsUser.isPresent() ? _generateUserSeries(ctx, vsUser) : null;
    final series =
        [userData, vsUserData].where((element) => element != null).toList();
    final chart = _generateChart(series);
    return Card(
        child: Column(children: [/*_createHeader(),*/ Expanded(child: chart)]));
  }

  Widget _generateChart(List<charts.Series<SolvedProblems, DateTime>> series) {
    print('generateChart, cumulative: ${cumulative}, group by: ${groupBy}');
    if (cumulative) {
      return charts.TimeSeriesChart(
        series,
        behaviors: [charts.SeriesLegend()],
        defaultRenderer: charts.LineRendererConfig<DateTime>(),
        defaultInteractions: true,
      );
    } else {
      return charts.TimeSeriesChart(
        series,
        behaviors: [charts.SeriesLegend()],
        defaultRenderer: charts.BarRendererConfig<DateTime>(),
        defaultInteractions: false,
      );
    }
  }

  charts.Series<SolvedProblems, DateTime> _generateUserSeries(BuildContext ctx,
      GenericUserData user) {
    final Map<DateTime, int> solvedByDay = _getUserSolvedByDay(ctx, user);
    return charts.Series<SolvedProblems, DateTime>(
        id: user.handle,
        colorFn: (_, __) => chartsColorOfMaterial(user.color),
        domainFn: (SolvedProblems problems, _) => problems.date,
        measureFn: (SolvedProblems problems, _) => problems.numSolved,
        data: solvedByDay.entries.map((entry) =>
            SolvedProblems(entry.key, entry.value)).toList());
  }

  Map<DateTime, int> _getUserSolvedByDay(BuildContext ctx,
      GenericUserData user) {
    final submissions = user.submissions;
    final contests = ctx.watch<ContestList>();
    final solvedAt = submissions
        .getSubmittedProblems(contests)
        .map((problem) => submissions.solvedWith(problem))
        .where((solution) => solution != null)
        .map((solution) => solution.time)
        .toList();
    solvedAt.sort();

    final solved = <DateTime, int>{};
    var solvedNum = 0;
    for (final solutionTime in solvedAt) {
      final day = _roundDate(solutionTime);
      solved[day] = (cumulative) ? ++solvedNum : 1 + (solved[day] ?? 0);
    }
    return solved;
  }

  DateTime _roundDate(DateTime solutionTime) {
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

  Widget _createHeader() {
    final header = ListTile(title: Text('Solved problems'), leading: Icon(Icons.assignment_turned_in));
    final cumulativeCtrl = SwitchListTile(
      value: cumulative,
      title: Text('Cumulative?'),
      secondary: Icon(Icons.add_circle),
      onChanged: (newValue) =>
          setState(() {
            cumulative = newValue;
          }),
    );
    final groupByCtrl = DropdownButton<GroupSolvedProblemsBy>(
      value: groupBy,
      icon: Icon(Icons.event),
      onChanged: (GroupSolvedProblemsBy newValue) {
        setState(() {
          groupBy = newValue;
        });
      },
      items: [GroupSolvedProblemsBy.day, GroupSolvedProblemsBy.month, GroupSolvedProblemsBy.year]
          .map((g) =>
          DropdownMenuItem<GroupSolvedProblemsBy>(
            value: g,
            child: Text(g.toString()),
          ))
          .toList(),
    );
    return Column(children: [header, cumulativeCtrl, groupByCtrl]);
  }
}

class SolvedProblems {
  final DateTime date;
  final int numSolved;

  SolvedProblems(this.date, this.numSolved);
}
