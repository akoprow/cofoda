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
  final String vsUser;
  final String filter;
  final int ratingLimit;

  ContestsListScreen({this.user, this.vsUser, this.ratingLimit, this.filter});

  @override
  Widget build(BuildContext context) => showFuture(
      CodeforcesAPI().load(users: [user, vsUser].where((u) => u != null).toList()),
      (Data data) =>
          LoadedContestsListWidget(data: data, ratingLimit: ratingLimit, filter: filter, user: user, vsUser: vsUser));
}

class LoadedContestsListWidget extends StatelessWidget {
  final String _user;
  final String _vsUser;
  final Data _data;
  final int _ratingLimit;
  final List<Contest> _allContests;
  final List<Contest> _contests;
  final Widget _stats;

  LoadedContestsListWidget.withContests(this._contests,
      {Key key, @required Data data, int ratingLimit, @required String filter, @required String user, String vsUser})
      : _data = data,
        _user = user,
        _vsUser = vsUser,
        _ratingLimit = ratingLimit,
        _allContests = data.contestList.allContests,
        _stats = _generateProblemStats(_contests, data: data, ratingLimit: ratingLimit, user: user, vsUser: vsUser),
        super(key: key);

  LoadedContestsListWidget({Key key, @required Data data, int ratingLimit, String filter, String user, String vsUser})
      : this.withContests(_filterContests(user, data, filter, ratingLimit: ratingLimit),
      key: key,
      data: data,
      filter: filter,
      ratingLimit: ratingLimit,
      user: user,
      vsUser: vsUser);

  static List<Contest> _filterContests(String user, Data data, String filter, {int ratingLimit}) {
    return data.contestList.allContests.where(_getContestFilter(user, data, filter, ratingLimit: ratingLimit)).toList();
  }

  static bool Function(Contest) _getContestFilter(String user, Data data, String filter, {int ratingLimit}) {
    return (Contest contest) {
      final statuses = contest.problems.map((p) => data.statusOfProblem(user, p, ratingLimit: ratingLimit)).toList();
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

  static Map<ProblemStatus, int> _computeStatsForUser(
      {@required List<Contest> contests, @required Data data, @required String user, @required int ratingLimit}) {
    final statuses = contests
        .map((contest) =>
        contest.problems.map((problem) => data.statusOfProblem(user, problem, ratingLimit: ratingLimit)))
        .expand((x) => x)
        .toList();
    return Map.fromIterables(ProblemStatus.values, ProblemStatus.values.map((status) =>
    statuses
        .where((s) => s == status)
        .length));
  }

  static Widget _generateProblemStats(List<Contest> contests,
      {Data data, int ratingLimit, String user, String vsUser}) {
    final statsForUser = (String forUser) =>
        _computeStatsForUser(contests: contests, data: data, user: forUser, ratingLimit: ratingLimit);
    final stats = statsForUser(user);
    final vsStats = vsUser != null ? statsForUser(vsUser) : null;
    final usersLabel = vsUser == null ? user : '${user} | ${vsUser}';
    return ListTile(leading: Text(usersLabel), title: Row(children: _renderStats(stats, vsStats)));
  }

  static List<Widget> _renderStats(Map<ProblemStatus, int> stats, Map<ProblemStatus, int> vsStats) {
    final numbersForStatus = (List<ProblemStatus> statuses) {
      final sumFor = (Map<ProblemStatus, int> stats) => statuses.map((status) => stats[status]).reduce((a, b) => a + b);
      final userNum = sumFor(stats);
      return vsStats == null ? userNum.toString() : '${userNum} | ${sumFor(vsStats)}';
    };
    final Widget Function(ProblemStatus) renderStatus = (status) =>
        Padding(
            padding: EdgeInsets.only(right: 5),
            child: Chip(
              label: Text(numbersForStatus([status])),
              backgroundColor: statusToColor(status),
            ));
    final solvedLive = numbersForStatus([ProblemStatus.solvedLive]);
    final solvedVirtual = numbersForStatus([ProblemStatus.solvedVirtual]);
    final solvedPractice = numbersForStatus([ProblemStatus.solvedPractice]);
    final solvedTotal = numbersForStatus(
        [ProblemStatus.solvedLive, ProblemStatus.solvedVirtual, ProblemStatus.solvedPractice]);
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
              (context, i) =>
              ContestListTileWidget(user: _user, contest: _contests[i], data: _data, ratingLimit: _ratingLimit),
          childCount: _contests.length,
        ));
    return Scaffold(body: CustomScrollView(slivers: [topBarSliver, contests]));
  }
}
