import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/ui/contestWidget.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/material.dart';

class DashboardWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DashboardWidgetState();
}

class DashboardWidgetState extends State<DashboardWidget> {
  final Future<Data> _data = CodeforcesAPI().load();

  @override
  Widget build(BuildContext context) => showFuture(_data, _showProblems);

  Widget _showContests(Data data) {
    final contests = data.contestList.contests;
    return Scrollbar(
        child: ListView.builder(itemCount: contests.length, itemBuilder: (context, i) => ContestWidget(contests[i])));
  }

  Widget _showProblems(Data data) {
    final problems = data.problemList.problems;
    final problemWidgets = problems.map((problem) => ProblemWidget(problem)).toList();
    return CustomScrollView(primary: true, slivers: <Widget>[
      SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid.extent(
              maxCrossAxisExtent: 400.0,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 4,
              children: problemWidgets))
    ]);
  }
}
