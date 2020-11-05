import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cofoda/data/userDataProvider.dart';
import 'package:cofoda/model/contest.dart';
import 'package:flutter/material.dart';

class ContestHistogram extends StatelessWidget {
  static const int numBuckets = 25;
  static DateTime SCORE_ROOT = DateTime(2000, 1, 1);

  final Widget _chart;

  ContestHistogram({Key key, Contest contest})
      : _chart = _generateChart(contest),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = BoxDecoration(
        border: Border.all(color: Colors.grey[500]), color: Colors.grey[200]);
    return Container(
        width: 80,
        height: 40,
        child: _chart,
        decoration: (_chart != null) ? border : null);
  }

  static Widget _generateChart(Contest contest) {
    if (contest.results == null) {
      return null;
    }
    final points = contest.results.pointDistribution;
    final data = List.generate(
        numBuckets, (index) => points.containsKey(index) ? points[index] : 0);
    final hist = charts.Series<int, DateTime>(
      id: 'Contest results',
      domainFn: (_, int index) => _dateOfIndex(index),
      measureFn: (int numPeople, _) => numPeople,
      colorFn: (_1, _2) => _chartsColor(Colors.grey[700]),
      data: data,
    );

    return withUsers((users) => charts.TimeSeriesChart(
          [hist],
          animate: false,
          defaultRenderer: charts.BarRendererConfig<DateTime>(),
          behaviors: [_usersScoreAnnotations(users)],
          primaryMeasureAxis: charts.NumericAxisSpec(
              showAxisLine: false, renderSpec: charts.NoneRenderSpec()),
          domainAxis:
              charts.DateTimeAxisSpec(renderSpec: charts.NoneRenderSpec()),
          layoutConfig: charts.LayoutConfig(
              leftMarginSpec: charts.MarginSpec.fixedPixel(0),
              topMarginSpec: charts.MarginSpec.fixedPixel(0),
              rightMarginSpec: charts.MarginSpec.fixedPixel(0),
              bottomMarginSpec: charts.MarginSpec.fixedPixel(0)),
        ));
  }

  static DateTime _dateOfIndex(int index) =>
      SCORE_ROOT.add(Duration(days: index));

  static charts.RangeAnnotation _usersScoreAnnotations(UsersData users) {
    return charts.RangeAnnotation(
        _scoreFor(users.user) + _scoreFor(users.vsUser));
  }

  static List<charts.LineAnnotationSegment<DateTime>> _scoreFor(
      GenericUserDataProvider user) {
    if (user.isReady()) {
      final scoreAsHours = 24;
      final score = SCORE_ROOT
          .subtract(Duration(hours: 12))
          .add(Duration(hours: scoreAsHours));
      print(score);
      return [
        charts.LineAnnotationSegment(
            score, charts.RangeAnnotationAxisType.domain,
            strokeWidthPx: 3.0, color: _chartsColor(user.color))
      ];
    } else {
      return [];
    }
  }
}

charts.Color _chartsColor(Color c) =>
    charts.Color(r: c.red, g: c.green, b: c.blue, a: c.alpha);
