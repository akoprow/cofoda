import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/*
 * TODO:
 * - refactor data into a common provider.
 */

class ContestsDashboardWidget extends StatelessWidget {
  final String user;

  ContestsDashboardWidget({this.user});

  @override
  Widget build(BuildContext context) =>
      showFuture(CodeforcesAPI().load(user: user), (Data data) => LoadedContestsDashboardWidget(data: data));
}

class LoadedContestsDashboardWidget extends StatelessWidget {
  final Data _data;
  final List<Contest> _contests;

  LoadedContestsDashboardWidget({Key key, @required Data data})
      : _data = data,
        _contests = data.contestList.allContests,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: ListView.builder(
      itemCount: _contests.length,
      itemBuilder: (context, i) => _showContest(_contests[i]),
    ));
  }

  Widget _showContest(Contest contest) {
    return Card(
      child: ListTile(title: Row(children: [Text(contest.name), Spacer()] + _showProblems(contest))),
    );
  }

  List<StatelessWidget> _showProblems(Contest contest) {
    return contest.problems
        .map(_showProblem)
        .toList()
        .reversed
        .toList();
  }

  StatelessWidget _showProblem(Problem problem) => Chip(
        label: Text(problem.index),
        backgroundColor: problemStatusToColor(_data.statusOfProblem(problem)),
      );
}
