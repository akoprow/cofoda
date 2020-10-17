import 'package:cofoda/main.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:flutter/material.dart';

import 'contestHistogram.dart';

class ContestListTileWidget extends StatelessWidget {
  final String _user;
  final String _vsUser;
  final Contest _contest;
  final int _ratingLimit;

  ContestListTileWidget(
      {@required String user,
      @required Contest contest,
      int ratingLimit,
      String vsUser})
      : _user = user,
        _vsUser = vsUser,
        _ratingLimit = ratingLimit,
        _contest = contest;

  @override
  Widget build(BuildContext context) {
    final contestId = Chip(label: Text('#' + _contest.id.toString()));
    final contestName = Text('  ' + _contest.name);
    final histogram = ContestHistogram(contest: _contest);
    final elements = [contestId, contestName, Spacer(flex: 3)] +
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
    return Chip(label: Text(problem.index), backgroundColor: Colors.grey[200]);
    /*
    final color1 = problemStatusToColor(_user, _data, problem, ratingLimit: _ratingLimit);
    if (_vsUser == null) {
      return Chip(label: Text(problem.index), backgroundColor: color1);
    } else {
      final color2 = problemStatusToColor(_vsUser, _data, problem, ratingLimit: _ratingLimit);
      return Chip2(
          label: Text('${problem.index} | ${problem.index}'), backgroundColor: color1, secondBackgroundColor: color2);
    }
    */
  }
}
