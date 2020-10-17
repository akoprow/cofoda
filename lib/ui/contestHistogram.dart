import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cofoda/model/contest.dart';
import 'package:flutter/material.dart';

class ContestHistogram extends StatelessWidget {
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
    final pointsAt =
        (int index) => points.containsKey(index) ? points[index] : 0;
    final data = List.generate(
        25, (index) => pointsAt(2 * index) + pointsAt(2 * index + 1));
    final hist = charts.Series<int, String>(
      id: 'Contest results',
      domainFn: (_, int index) => index.toString(),
      measureFn: (int numPeople, _) => numPeople,
      colorFn: (_1, _2) => _chartsColor(Colors.grey[700]),
      data: data,
    );

    return charts.BarChart(
      [hist],
      animate: false,
      primaryMeasureAxis:
          charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
      domainAxis: charts.OrdinalAxisSpec(
          showAxisLine: false, renderSpec: charts.NoneRenderSpec()),
      layoutConfig: charts.LayoutConfig(
          leftMarginSpec: charts.MarginSpec.fixedPixel(0),
          topMarginSpec: charts.MarginSpec.fixedPixel(0),
          rightMarginSpec: charts.MarginSpec.fixedPixel(0),
          bottomMarginSpec: charts.MarginSpec.fixedPixel(0)),
    );
  }
}

charts.Color _chartsColor(Color c) =>
    charts.Color(r: c.red, g: c.green, b: c.blue, a: c.alpha);
