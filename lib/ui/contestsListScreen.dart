import 'dart:core';

import 'package:cofoda/data/codeforcesAPI.dart';
import 'package:cofoda/data/userDataProvider.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/contestListTileWidget.dart';
import 'package:cofoda/ui/problemWidget.dart';
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

  static List<Contest> _filterContests(List<Contest> contests) {
    final contestFilter = (Contest contest) {
      /*
      final statuses = contest.problems
          .map((p) => statusOfProblem(user, p, ratingLimit: ratingLimit))
          .toList();
      return statuses.any(_getContestStatusPredicate(data, filter));
       */
      return true;
    };

    return contests.where(contestFilter).toList();
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
      List<Contest> contests, GenericUserDataProvider user) {
    final statuses = contests
        .map((contest) => contest.problems.map((problem) => user.submissions
            .statusOfProblem(problem, ratingLimit: _ratingLimit)))
        .expand((x) => x)
        .toList();
    return Map.fromIterables(
        ProblemStatus.values,
        ProblemStatus.values
            .map((status) => statuses.where((s) => s == status).length));
  }

  Widget _userContainer(GenericUserDataProvider user) {
    return Text(user.handle + ((user.isLoading) ? ' (loading...)' : ''));
  }

  Widget _generateProblemStats(List<Contest> contests, UserDataProvider user,
      VsUserDataProvider vsUser) {
    if (!user.isPresent()) {
      return Container();
    }
    final genStats = (GenericUserDataProvider user) =>
        user.isReady() ? _computeStatsForUser(contests, user) : null;
    final stats = genStats(user);
    final vsStats = genStats(vsUser);
    final users = vsUser.isPresent()
        ? Row(children: [
            _userContainer(user),
            Text(' | '),
            _userContainer(vsUser)
          ], mainAxisSize: MainAxisSize.min)
        : _userContainer(user);
    return ListTile(
        leading: users,
        title: Row(children: _renderStats(stats, vsStats, vsUser.isPresent())));
  }

  static String _statsForStatus(
      List<ProblemStatus> statuses,
      Map<ProblemStatus, int> stats,
      Map<ProblemStatus, int> vsStats,
      bool secondUser) {
    final sumFor = (Map<ProblemStatus, int> stats) => (stats == null)
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
    final Widget Function(ProblemStatus) renderStatus = (status) => Padding(
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
    return ProblemStatus.values.reversed.map(renderStatus).toList() +
        [explanation];
  }

  @override
  Widget build(BuildContext context) => _show(context.watch<List<Contest>>());

  Widget _topBarSliver(List<Contest> allContests, List<Contest> contests) {
    final summaryText = (allContests.length == contests.length)
        ? 'Displaying all ${contests.length} contests'
        : 'Displaying ${contests.length}/${allContests.length} contests';
    final stats = withUsers(
            (user, vsUser) => _generateProblemStats(contests, user, vsUser));
    final topBar =
    Card(child: ListTile(title: stats, subtitle: Text(summaryText)));
    return SliverList(
        delegate:
        SliverChildBuilderDelegate((context, i) => topBar, childCount: 1));
  }

  Widget _contestsSliver(List<Contest> contests) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) =>
              ContestListTileWidget(
                  contest: contests[i], ratingLimit: _ratingLimit),
          childCount: contests.length,
        ));
  }

  Widget _show(List<Contest> allContests) {
    if (allContests == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final contests = _filterContests(allContests);

    return Scaffold(
        body: CustomScrollView(slivers: [
          _topBarSliver(allContests, contests),
          _contestsSliver(contests)
        ]));
  }
}
