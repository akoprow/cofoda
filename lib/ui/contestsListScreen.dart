import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
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
  final int ratingLimit;

  ContestsListScreen({this.user, this.ratingLimit});

  @override
  Widget build(BuildContext context) => showFuture(
      CodeforcesAPI().load(user: user), (Data data) => LoadedContestsListWidget(data: data, ratingLimit: ratingLimit));
}

class LoadedContestsListWidget extends StatelessWidget {
  final Data _data;
  final int _ratingLimit;
  final List<Contest> _contests;

  LoadedContestsListWidget({Key key, @required Data data, int ratingLimit})
      : _data = data,
        _ratingLimit = ratingLimit,
        _contests = data.contestList.allContests,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = 'displaying all ${_contests.length} contests';
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
