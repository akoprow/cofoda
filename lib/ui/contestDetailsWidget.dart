import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ContestDetailsWidget extends StatelessWidget {
  final String user;
  final String contestId;

  ContestDetailsWidget({this.user, this.contestId});

  @override
  Widget build(BuildContext context) =>
      showFuture(CodeforcesAPI().load(user: user), (Data data) => LoadedSingleContestWidget(data: data));
}

class LoadedSingleContestWidget extends StatefulWidget {
  final Data _data;

  LoadedSingleContestWidget({Key key, @required Data data})
      : _data = data,
        super(key: key);

  @override
  State<StatefulWidget> createState() => LoadedSingleContestWidgetState();
}

class LoadedSingleContestWidgetState extends State<LoadedSingleContestWidget> {
  @override
  Widget build(BuildContext context) => Text('TODO');
}
