import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/contestListTileWidget.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/*
 * TODO:
 * - refactor data into a common provider.
 */
class ContestsListWidget extends StatelessWidget {
  final String _user;
  final String _vsUser;
  final String _filter;
  final int _ratingLimit;

  const ContestsListWidget(
      {Key key, String user, String vsUser, String filter, int ratingLimit})
      : _user = user,
        _vsUser = vsUser,
        _filter = filter,
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

  Map<ProblemStatus, int> _computeStatsForUser(List<Contest> contests) {
    return {};
    /*
    final statuses = contests
        .map((contest) => contest.problems.map((problem) =>
            data.statusOfProblem(user, problem, ratingLimit: ratingLimit)))
        .expand((x) => x)
        .toList();
    return Map.fromIterables(
        ProblemStatus.values,
        ProblemStatus.values
            .map((status) => statuses.where((s) => s == status).length));
     */
  }

  Widget _generateProblemStats(List<Contest> contests) {
    final statsForUser = (String forUser) => _computeStatsForUser(contests);
    final stats = statsForUser(_user);
    final vsStats = _vsUser != null ? statsForUser(_vsUser) : null;
    final usersLabel = _vsUser == null ? _user : '${_user} | ${_vsUser}';
    return ListTile(
        leading: Text(usersLabel),
        title: Row(children: _renderStats(stats, vsStats)));
  }

  static List<Widget> _renderStats(
      Map<ProblemStatus, int> stats, Map<ProblemStatus, int> vsStats) {
    final numbersForStatus = (List<ProblemStatus> statuses) {
      final sumFor = (Map<ProblemStatus, int> stats) =>
          statuses.map((status) => stats[status]).reduce((a, b) => a + b);
      final userNum = sumFor(stats);
      return vsStats == null
          ? userNum.toString()
          : '${userNum} | ${sumFor(vsStats)}';
    };
    final Widget Function(ProblemStatus) renderStatus = (status) => Padding(
        padding: EdgeInsets.only(right: 5),
        child: Chip(
          label: Text(numbersForStatus([status])),
          backgroundColor: statusToColor(status),
        ));
    final solvedLive = numbersForStatus([ProblemStatus.solvedLive]);
    final solvedVirtual = numbersForStatus([ProblemStatus.solvedVirtual]);
    final solvedPractice = numbersForStatus([ProblemStatus.solvedPractice]);
    final solvedTotal = numbersForStatus([
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
  Widget build(BuildContext context) {
    final Query contests = FirebaseFirestore.instance
        .collection('contests')
        .orderBy('startTimeSeconds', descending: true);

    return StreamBuilder<QuerySnapshot>(
        stream: contests.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text(':(');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          return _show(snapshot.data.docs);
        });
  }

  Widget _show(List<QueryDocumentSnapshot> fireContests) {
    final allContests = fireContests.map((c) => Contest.fromFire(c)).toList();
    final contests = _filterContests(allContests);

    final summaryText = (allContests.length == contests.length)
        ? 'Displaying all ${contests.length} contests'
        : 'Displaying ${contests.length}/${allContests.length} contests';
    final stats = Container(); // TODO _generateProblemStats(contests);
    final topBar =
        Card(child: ListTile(title: stats, subtitle: Text(summaryText)));
    final topBarSliver = SliverList(
        delegate:
            SliverChildBuilderDelegate((context, i) => topBar, childCount: 1));
    final contestsWidget = SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, i) => ContestListTileWidget(
          user: _user,
          vsUser: _vsUser,
          contest: contests[i],
          ratingLimit: _ratingLimit),
      childCount: contests.length,
    ));
    return Scaffold(
        body: CustomScrollView(slivers: [topBarSliver, contestsWidget]));
  }
}
