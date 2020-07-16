import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/ui/contestWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/material.dart';

class DashboardWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DashboardWidgetState();
}

class DashboardWidgetState extends State<DashboardWidget> {
  final Future<ContestList> _contests = CodeforcesAPI().getAllContests();

  @override
  Widget build(BuildContext context) => showFuture(_contests, _showContests);

  Widget _showContests(ContestList contests) {
    final tiles = contests.contests
        .where((contest) => contest.phase == 'FINISHED')
        .map((contest) => ContestWidget(contest))
        .toList();
    return Scrollbar(child: ListView(children: tiles));
  }
}
