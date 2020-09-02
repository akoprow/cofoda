import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/main.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/material.dart';

import 'chip2.dart';

class ContestListTileWidget extends StatelessWidget {
  final String _user;
  final String _vsUser;
  final Contest _contest;
  final Data _data;
  final int _ratingLimit;

  ContestListTileWidget(
      {@required String user, @required Contest contest, @required Data data, int ratingLimit, String vsUser})
      : _data = data,
        _user = user,
        _vsUser = vsUser,
        _ratingLimit = ratingLimit,
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
    final card = _buildCard(problem);
    return GestureDetector(onTap: () => problem.open(), child: card);
  }

  Widget _buildCard(Problem problem) {
    final color1 = problemStatusToColor(_user, _data, problem, ratingLimit: _ratingLimit);
    if (_vsUser == null) {
      return Chip(label: Text(problem.index), backgroundColor: color1);
    } else {
      final color2 = problemStatusToColor(_vsUser, _data, problem, ratingLimit: _ratingLimit);
      return Chip2(
          label: Text('${problem.index} | ${problem.index}'), backgroundColor: color1, secondBackgroundColor: color2);
    }
  }
}
