import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/material.dart';

class ContestWidget extends StatelessWidget {
  final Contest contest;
  final Data data;

  ContestWidget({this.contest, this.data});

  @override
  Widget build(BuildContext context) {
    final problems = contest.problems.toList();
    problems.sort();

    final tile = ListTile(
        leading: Text(contest.id.toString()),
        title: Row(children: [
          Text(contest.name),
          Spacer(),
          Row(children: problems.map((problem) => ProblemWidget.of(data, problem)).toList())
        ]));
    return Card(child: Column(mainAxisSize: MainAxisSize.min, children: [tile]));
  }
}
