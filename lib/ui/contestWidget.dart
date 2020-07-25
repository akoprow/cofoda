import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:flutter/material.dart';

class ContestWidget extends StatelessWidget {
  final Contest _contest;
  final Data _data;

  ContestWidget({Contest contest, Data data})
      : _data = data,
        _contest = contest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Row(children: [Text(_contest.name), Spacer()] + _showProblems())),
    );
  }

  List<StatelessWidget> _showProblems() {
    return _contest.problems.map(_showProblem).toList().reversed.toList();
  }

  StatelessWidget _showProblem(Problem problem) {
    final card = Chip(
      label: Text(problem.index),
      backgroundColor: _problemStatusToColor(_data.statusOfProblem(problem)),
    );
    return GestureDetector(onTap: () => problem.open(), child: card);
  }

  Color _problemStatusToColor(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.solvedLive:
        return Colors.green[700];
      case ProblemStatus.solvedVirtual:
        return Colors.green[400];
      case ProblemStatus.solvedPractice:
        return Colors.green[100];
      case ProblemStatus.tried:
        return Colors.red[400];
      default:
        return Colors.grey;
    }
  }
}
