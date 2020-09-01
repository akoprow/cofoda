import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/contestListTileWidget.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/*
 * TODO:
 * - refactor data into a common provider.
 */

class ContestsListScreen extends StatelessWidget {
  final String user;
  final String filter;
  final int ratingLimit;

  ContestsListScreen({this.user, this.ratingLimit, this.filter});

  @override
  Widget build(BuildContext context) => showFuture(CodeforcesAPI().load(user: user),
      (Data data) => LoadedContestsListWidget(data: data, ratingLimit: ratingLimit, filter: filter, user: user));
}

class LoadedContestsListWidget extends StatelessWidget {
  final Data _data;
  final int _ratingLimit;
  final List<Contest> _allContests;
  final List<Contest> _contests;
  final Widget _stats;

  LoadedContestsListWidget.withContests(this._contests,
      {Key key, @required Data data, int ratingLimit, String filter, String user})
      : _data = data,
        _ratingLimit = ratingLimit,
        _allContests = data.contestList.allContests,
        _stats = _generateProblemStats(_contests, data: data, ratingLimit: ratingLimit, user: user),
        super(key: key);

  LoadedContestsListWidget({Key key, @required Data data, int ratingLimit, String filter, String user})
      : this.withContests(_filterContests(data, filter, ratingLimit: ratingLimit),
            key: key, data: data, ratingLimit: ratingLimit, user: user);

  static List<Contest> _filterContests(Data data, String filter, {int ratingLimit}) {
    return data.contestList.allContests.where(_getContestFilter(data, filter, ratingLimit: ratingLimit)).toList();
  }

  static bool Function(Contest) _getContestFilter(Data data, String filter, {int ratingLimit}) {
    return (Contest contest) {
      final statuses = contest.problems.map((p) => data.statusOfProblem(p, ratingLimit: ratingLimit)).toList();
      return statuses.any(_getContestStatusPredicate(data, filter));
    };
  }

  static bool Function(ProblemStatus) _getContestStatusPredicate(Data data, String filter) {
    if (filter == null) return (status) => true;
    return (ProblemStatus s) {
      switch (filter) {
        case 'todo':
          return s == ProblemStatus.tried || s == ProblemStatus.toUpSolve;
        case 'failed':
          return s == ProblemStatus.tried;
        case 'solved':
          return s == ProblemStatus.solvedPractice || s == ProblemStatus.solvedVirtual || s == ProblemStatus.solvedLive;
        default:
          throw 'Unknown filter: $filter';
      }
    };
  }

  static Widget _generateProblemStats(List<Contest> contests, {Data data, int ratingLimit, String user}) {
    final statuses = contests
        .map((contest) => contest.problems.map((problem) => data.statusOfProblem(problem, ratingLimit: ratingLimit)))
        .expand((x) => x)
        .toList();
    final Map<ProblemStatus, int> stats = Map.fromIterables(
        ProblemStatus.values, ProblemStatus.values.map((status) => statuses.where((s) => s == status).length));
    return ListTile(leading: Text(user), title: Row(children: _renderStats(stats)));
  }

  static List<Widget> _renderStats(Map<ProblemStatus, int> stats) {
    final Widget Function(ProblemStatus) renderStatus = (status) =>
        Padding(
            padding: EdgeInsets.only(right: 5),
            child: Chip(
              label: Text(stats[status].toString()),
              backgroundColor: statusToColor(status),
            ));
    final solvedLive = stats[ProblemStatus.solvedLive];
    final solvedVirtual = stats[ProblemStatus.solvedVirtual];
    final solvedPractice = stats[ProblemStatus.solvedPractice];
    final solvedTotal = solvedLive + solvedVirtual + solvedPractice;
    final explanation = Text('($solvedLive + $solvedVirtual + $solvedPractice = $solvedTotal solved)');
    return ProblemStatus.values.reversed.map(renderStatus).toList() + [explanation];
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = (_allContests.length == _contests.length)
        ? 'Displaying all ${_contests.length} contests'
        : 'Displaying ${_contests.length}/${_allContests.length} contests';
    final topBar = Card(child: ListTile(title: _stats, subtitle: Text(summaryText)));
    final topBarSliver = SliverList(delegate: SliverChildBuilderDelegate((context, i) => topBar, childCount: 1));
    final contests = SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) => ContestListTileWidget(contest: _contests[i], data: _data, ratingLimit: _ratingLimit),
      childCount: _contests.length,
    ));
    return Scaffold(body: CustomScrollView(slivers: [topBarSliver, contests]));
  }
}
