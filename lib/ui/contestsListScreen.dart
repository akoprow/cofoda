import 'dart:core';

import 'package:dashforces/data/codeforcesAPI.dart';
import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/data/userData.dart';
import 'package:dashforces/model/contest.dart';
import 'package:dashforces/model/contestList.dart';
import 'package:dashforces/model/submissions.dart';
import 'package:dashforces/ui/contestListTileWidget.dart';
import 'package:dashforces/ui/problemWidget.dart';
import 'package:dashforces/ui/scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ContestsListWidget extends StatelessWidget {
  final String _filter;
  final int _ratingLimit;

  const ContestsListWidget({Key key, String filter, int ratingLimit})
      : _filter = filter,
        _ratingLimit = ratingLimit,
        super(key: key);

  static ContestList _filterContests(ContestList contests) {
    final contestFilter = (Contest contest) {
      /*
      final statuses = contest.problems
          .map((p) => statusOfProblem(user, p, ratingLimit: ratingLimit))
          .toList();
      return statuses.any(_getContestStatusPredicate(data, filter));
       */
      return true;
    };

    return ContestList(contests.contests.where(contestFilter).toList());
  }

  static bool Function(ProblemStatus) _getContestStatusPredicate(
      Data data, String filter) {
    if (filter == null) return (status) => true;
    return (ProblemStatus s) {
      switch (filter) {
        case 'todo':
          return s == ProblemStatus.tried || s == ProblemStatus.toUpSolve;
        case 'failed':
          return s == ProblemStatus.tried;
        case 'solved':
          return s == ProblemStatus.solvedPractice ||
              s == ProblemStatus.solvedVirtual ||
              s == ProblemStatus.solvedLive;
        default:
          throw 'Unknown filter: $filter';
      }
    };
  }

  Map<ProblemStatus, int> _computeStatsForUser(
      ContestList contests, GenericUserData user) {
    final statuses = contests.contests
        .map((contest) => contest.problems.map((problem) => user.submissions
            .statusOfProblem(contest, problem, ratingLimit: _ratingLimit)))
        .expand((x) => x)
        .toList();
    return Map.fromIterables(
        ProblemStatus.values,
        ProblemStatus.values
            .map((status) => statuses.where((s) => s == status).length));
  }

  Widget _userContainer(GenericUserData user) {
    return Text(user.handle + ((user.isLoading) ? ' (loading...)' : ''));
  }

  Widget _generateProblemStats(ContestList contests, BothUsersData users) {
    final UserData user = users.user;
    final vsUser = users.vsUser;
    if (!user.isPresent()) {
      return Container();
    }
    final genStats = (GenericUserData user) =>
    user.isPresent() ? _computeStatsForUser(contests, user) : null;
    final stats = genStats(user);
    final vsStats = genStats(vsUser);
    final userLabels = vsUser.isPresent()
        ? Row(children: [
      _userContainer(user),
      Text(' | '),
      _userContainer(vsUser)
    ], mainAxisSize: MainAxisSize.min)
        : _userContainer(user);
    return ListTile(
        leading: userLabels,
        title: Row(children: _renderStats(stats, vsStats, vsUser.isPresent())));
  }

  static String _statsForStatus(List<ProblemStatus> statuses,
      Map<ProblemStatus, int> stats,
      Map<ProblemStatus, int> vsStats,
      bool secondUser) {
    final sumFor = (Map<ProblemStatus, int> stats) =>
    (stats == null)
        ? '?'
        : statuses
        .map((status) => stats[status] ?? 0)
        .reduce((a, b) => a + b)
        .toString();
    return secondUser
        ? '${sumFor(stats)} | ${sumFor(vsStats)}'
        : '${sumFor(stats)}';
  }

  static List<Widget> _renderStats(Map<ProblemStatus, int> stats,
      Map<ProblemStatus, int> vsStats, bool secondUser) {
    final getStats = (List<ProblemStatus> statuses) =>
        _statsForStatus(statuses, stats, vsStats, secondUser);
    final Widget Function(ProblemStatus) renderStatus = (status) =>
        Padding(
            padding: EdgeInsets.only(right: 5),
            child: Chip(
              label: Text(getStats([status])),
              backgroundColor: statusToColor(status),
            ));
    final solvedLive = getStats([ProblemStatus.solvedLive]);
    final solvedVirtual = getStats([ProblemStatus.solvedVirtual]);
    final solvedPractice = getStats([ProblemStatus.solvedPractice]);
    final solvedTotal = getStats([
      ProblemStatus.solvedLive,
      ProblemStatus.solvedVirtual,
      ProblemStatus.solvedPractice
    ]);
    final explanation = Text(
        '($solvedLive + $solvedVirtual + $solvedPractice = $solvedTotal solved)');
    return ProblemStatus.values.reversed
        .where((status) => status != ProblemStatus.solvedElsewhere)
        .map(renderStatus)
        .toList() +
        [explanation];
  }

  @override
  Widget build(BuildContext ctx) {
    final allContests = ctx.watch<ContestList>();
    final contests = _filterContests(allContests);
    return display(
        ctx, _show(contests, contests),
        screenTitle: _title(allContests, contests));
  }

  String _title(ContestList all, ContestList shown) {
    if (all.contests.length == shown.contests.length) {
      return 'Displaying all ${shown.contests.length} contests';
    } else {
      return 'Displaying ${shown.contests.length}/${all.contests
          .length} contests';
    }
  }

  Widget _topBarSliver(ContestList all, ContestList shown) {
    final stats = withUsers((users) => _generateProblemStats(shown, users));
    final topBar =
    Card(child: ListTile(title: stats));
    return SliverList(
        delegate:
        SliverChildBuilderDelegate((context, i) => topBar, childCount: 1));
  }

  Widget _contestsSliver(ContestList contests) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) =>
              ContestListTileWidget(
                  contest: contests.contests[i], ratingLimit: _ratingLimit),
          childCount: contests.contests.length,
        ));
  }

  Widget _show(ContestList allContests, ContestList contests) {
    if (allContests == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        body: CustomScrollView(slivers: [
          _topBarSliver(allContests, contests),
          _contestsSliver(contests)
        ]));
  }
}
