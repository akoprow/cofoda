import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SingleContestWidget extends StatelessWidget {
  final String user;
  final String contestId;

  SingleContestWidget({this.user, this.contestId});

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
  State<StatefulWidget> createState() {
    return LoadedSingleContestWidgetState();
  }
}

class LoadedSingleContestWidgetState extends State<LoadedSingleContestWidget> {
  @override
  Widget build(BuildContext context) => Text('TODO');
}
