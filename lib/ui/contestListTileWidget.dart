import 'package:cofoda/data/userDataProvider.dart';
import 'package:cofoda/main.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/material.dart';

import 'chip2.dart';
import 'contestHistogram.dart';

class ContestListTileWidget extends StatelessWidget {
  final Contest _contest;
  final int _ratingLimit;

  ContestListTileWidget({@required Contest contest, int ratingLimit})
      : _ratingLimit = ratingLimit,
        _contest = contest;

  @override
  Widget build(BuildContext context) {
    final contestId = Chip(label: Text('#' + _contest.id.toString()));
    final contestName = Expanded(
        child: Text('  ' + _contest.name, overflow: TextOverflow.ellipsis));
    final histogram = ContestHistogram(contest: _contest);
    final elements = [contestId, contestName] +
        _showProblems() +
        [Container(width: 10), histogram];
    return Card(
        child: ListTile(
            title: Row(children: elements),
            onTap: () => _goToContest(context)));
  }

  Future<void> _goToContest(BuildContext context) async {
    final routeName =
        AppComponentState.routeSingleContestPrefix + _contest.id.toString();
    return Navigator.pushNamed(context, routeName);
  }

  List<StatelessWidget> _showProblems() {
    return _contest.problems.map(_showProblem).toList();
  }

  StatelessWidget _showProblem(Problem problem) {
    final card = _buildCard(problem);
    return GestureDetector(onTap: () => problem.open(), child: card);
  }

  Widget _buildCard(Problem problem) {
    return withUsers((user, vsUser) {
      if (user.present()) {
        final color1 =
            user.problemStatusToColor(problem, ratingLimit: _ratingLimit);
        if (vsUser.present()) {
          final color2 =
              vsUser.problemStatusToColor(problem, ratingLimit: _ratingLimit);
          final text = '${problem.index} | ${problem.index}';
          return Chip2(
              label: Text(text),
              backgroundColor: color1,
              secondBackgroundColor: color2);
        } else {
          return Chip(label: Text(problem.index), backgroundColor: color1);
        }
      } else {
        return Chip(
            label: Text(problem.index),
            backgroundColor: statusToColor(ProblemStatus.untried));
      }
    });
  }
}
