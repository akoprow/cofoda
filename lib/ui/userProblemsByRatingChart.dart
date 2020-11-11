import 'package:charts_flutter/flutter.dart' as charts;
import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/data/userData.dart';
import 'package:dashforces/model/contestList.dart';
import 'package:dashforces/ui/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProblemsByRatingChart extends StatelessWidget {
  const UserProblemsByRatingChart({Key key}) : super(key: key);

  @override
  Widget build(BuildContext ctx) =>
      withUsers((userData) => _show(ctx, userData));

  Widget _show(BuildContext ctx, BothUsersData users) {
    if (!users.user.isPresent()) {
      return Text(
          "Please provide one or two users via 'users' URL query parameter.");
    }
    final contests = ctx.watch<ContestList>();
    final userData = _generateUserSeries(contests, users.user);
    final vsUserData = users.vsUser.isPresent()
        ? _generateUserSeries(contests, users.vsUser)
        : null;
    final series =
        [userData, vsUserData].where((element) => element != null).toList();
    final chart = _generateChart(series);
    return Card(child: Column(children: [Expanded(child: chart)]));
  }

  Widget _generateChart(
      List<charts.Series<MapEntry<int, int>, String>> series) {
    return charts.BarChart(
      series,
      animate: true,
      barGroupingType: charts.BarGroupingType.grouped,
      behaviors: [charts.SeriesLegend()],
    );
  }

  charts.Series<MapEntry<int, int>, String> _generateUserSeries(
      ContestList contests, GenericUserData user) {
    final submissions = user.submissions;
    final solved = submissions
        .getSubmittedProblems(contests)
        .map((problem) =>
            MapEntry(problem.rating, submissions.solvedWith(problem)))
        .where((entry) => entry.key != null && entry.value != null)
        .toList();

    final map = <int, int>{};
    solved.forEach((solved) => map[solved.key] = 1 + (map[solved.key] ?? 0));
    final data = map.entries.toList();
    data.sort((u, v) => u.key.compareTo(v.key));

    return charts.Series<MapEntry<int, int>, String>(
      id: user.handle,
      colorFn: (_1, _2) => chartsColorOfMaterial(user.color),
      domainFn: (entry, _) => entry.key.toString(),
      measureFn: (entry, _) => entry.value,
      data: data,
    );
  }
}
