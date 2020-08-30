import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/contestListTileWidget.dart';
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
      (Data data) => LoadedContestsListWidget(data: data, ratingLimit: ratingLimit, filter: filter));
}

class LoadedContestsListWidget extends StatelessWidget {
  final Data _data;
  final int _ratingLimit;
  final List<Contest> _allContests;
  final List<Contest> _contests;

  LoadedContestsListWidget({Key key, @required Data data, int ratingLimit, String filter})
      : _data = data,
        _ratingLimit = ratingLimit,
        _allContests = data.contestList.allContests,
        _contests = _filterContests(data, filter, ratingLimit: ratingLimit),
        super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final label = (_allContests.length == _contests.length)
        ? 'displaying all ${_contests.length} contests'
        : 'displaying ${_contests.length}/${_allContests.length} contests';
    final contests = SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) => ContestListTileWidget(contest: _contests[i], data: _data, ratingLimit: _ratingLimit),
      childCount: _contests.length,
    ));
    final appBar = SliverAppBar(
        expandedHeight: 150.0,
        floating: true,
        flexibleSpace: FlexibleSpaceBar(title: Text('Codeforces contests: $label')));
    return Scaffold(body: CustomScrollView(slivers: [appBar, contests]));
  }
}
