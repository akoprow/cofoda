import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/main.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/material.dart';

class ContestListTileWidget extends StatelessWidget {
  final Contest _contest;
  final Data _data;

  ContestListTileWidget({Contest contest, Data data})
      : _data = data,
        _contest = contest;

  @override
  Widget build(BuildContext context) {
    final contestId = Chip(label: Text('#' + _contest.id.toString()));
    final contestName = Text('  ' + _contest.name);
    return Card(
        child: ListTile(
            title: Row(children: [contestId, contestName, Spacer()] + _showProblems()),
            onTap: () => _goToContest(context)));
  }

  Future<void> _goToContest(BuildContext context) async {
    final routeName = AppComponentState.routeSingleContestPrefix + _contest.id.toString();
    return Navigator.pushNamed(context, routeName);
  }

  List<StatelessWidget> _showProblems() {
    return _contest.problems.map(_showProblem).toList().reversed.toList();
  }

  StatelessWidget _showProblem(Problem problem) {
    final card = Chip(
      label: Text(problem.index),
      backgroundColor: problemStatusToColor(_data.statusOfProblem(problem)),
    );
    return GestureDetector(onTap: () => problem.open(), child: card);
  }
}
