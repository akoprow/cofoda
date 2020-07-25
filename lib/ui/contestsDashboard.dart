import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
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
  final Data data;

  const LoadedContestsDashboardWidget({Key key, this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('Coming soon');
  }
}
