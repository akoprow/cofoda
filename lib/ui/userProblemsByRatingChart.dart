import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cofoda/codeforcesAPI.dart';
import 'package:flutter/material.dart';

class UserProblemsByRatingChart extends StatefulWidget {
  final List<String> users;
  final Data data;

  const UserProblemsByRatingChart({Key key, this.users, this.data}) : super(key: key);

  @override
  State<UserProblemsByRatingChart> createState() => UserProblemsByRatingChartState();
}

class UserProblemsByRatingChartState extends State<UserProblemsByRatingChart> {
  UserProblemsByRatingChartState();

  @override
  Widget build(BuildContext context) {
    final userData = _generateUserSeries(widget.users[0], charts.MaterialPalette.blue.shadeDefault);
    final vsUserData =
        widget.users[1] == null ? null : _generateUserSeries(widget.users[1], charts.MaterialPalette.red.shadeDefault);
    final series = [userData, vsUserData].where((element) => element != null).toList();
    final chart = _generateChart(series);
    return Card(child: Column(children: [Expanded(child: chart)]));
  }

  Widget _generateChart(List<charts.Series<MapEntry<int, int>, String>> series) {
    return charts.BarChart(
      series,
      animate: true,
      barGroupingType: charts.BarGroupingType.grouped,
      behaviors: [charts.SeriesLegend()],
    );
  }

  charts.Series<MapEntry<int, int>, String> _generateUserSeries(String user, charts.Color color) {
    final submissions = widget.data.userSubmissions[user];
    final solved = submissions.submittedProblems
        .map((problem) => MapEntry(problem.rating, submissions.solvedWith(problem)))
        .where((entry) => entry.key != null && entry.value != null)
        .toList();

    final map = <int, int>{};
    solved.forEach((solved) => map[solved.key] = 1 + (map[solved.key] ?? 0));
    final data = map.entries.toList();
    data.sort((u, v) => u.key.compareTo(v.key));

    return charts.Series<MapEntry<int, int>, String>(
      id: user,
      colorFn: (_1, _2) => color,
      domainFn: (entry, _) => entry.key.toString(),
      measureFn: (entry, _) => entry.value,
      data: data,
    );
  }
}
