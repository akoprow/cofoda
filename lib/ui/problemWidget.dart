import 'package:cofoda/model/problem.dart';
import 'package:flutter/material.dart';

class ProblemWidget extends StatelessWidget {
  final Problem problem;

  ProblemWidget(this.problem);

  @override
  Widget build(BuildContext context) => Chip(label: Text(problem.index));
}
