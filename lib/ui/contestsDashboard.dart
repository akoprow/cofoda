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
    return Scrollbar(
        child: ListView.builder(
      itemCount: _contests.length,
      itemBuilder: (context, i) => ContestWidget(contest: _contests[i], data: _data),
    ));
  }
}
