import 'package:cofoda/model/contest.dart';
import 'package:flutter/material.dart';

class ContestWidget extends StatelessWidget {
  final Contest contest;

  ContestWidget(this.contest);

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(title: Text(contest.name));
    return Card(child: Column(mainAxisSize: MainAxisSize.min, children: [tile]));
  }
}
