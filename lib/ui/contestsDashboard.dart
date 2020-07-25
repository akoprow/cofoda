import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/ui/contestWidget.dart';
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
    final label = 'displaying all ${_contests.length} contests';
    final contests = SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, i) => ContestWidget(contest: _contests[i], data: _data),
      childCount: _contests.length,
    ));
    final appBar = SliverAppBar(
        expandedHeight: 150.0,
        floating: true,
        flexibleSpace: FlexibleSpaceBar(title: Text('Codeforces contests: $label')));
    return Scaffold(body: CustomScrollView(slivers: [appBar, contests]));
  }
}
