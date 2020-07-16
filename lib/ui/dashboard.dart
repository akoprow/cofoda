import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/ui/contestWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/material.dart';

class ProblemsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ProblemsWidgetState();
}

class ProblemsWidgetState extends State<ProblemsWidget> {

  final Future<ContestList> _contests = CodeforcesAPI().getAllContests();

  @override
  Widget build(BuildContext context) => showFuture(_contests, _showContests);

  Widget _showContests(ContestList contests) {
    return Column(children: contests.contests.map((contest) => ContestWidget(contest)).toList());
  }
}
