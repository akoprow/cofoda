import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardLoaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      // TODO: Take user from the URL
      showFuture(CodeforcesAPI().load(user: 'koper'), (Data data) => DashboardWidget(data: data));
}

abstract class Group<T> {
  final List<Problem> matchingProblems;
  final List<Problem> displayableProblems;
  bool isExpanded = false;

  Group(List<Problem> allProblems, bool Function(Problem) problemFilter, bool Function(Problem) groupMembership)
      : this._fromMatchingProblems(allProblems.where(groupMembership).toList(), problemFilter);

  Group._fromMatchingProblems(this.matchingProblems, bool Function(Problem) problemFilter)
      : displayableProblems = matchingProblems.where(problemFilter).toList();

  String get _headerBase;

  String get header => '$_headerBase [${displayableProblems.length} / ${matchingProblems.length}]';
}

class GroupByProblemType extends Group<String> {
  final String _tag;

  GroupByProblemType(this._tag, List<Problem> allProblems, bool Function(Problem) problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.tags.contains(_tag));

  @override
  String get _headerBase => _tag;
}

class DashboardWidget extends StatefulWidget {
  final Data data;

  const DashboardWidget({Key key, this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DashboardWidgetState();
}

class DashboardWidgetState extends State<DashboardWidget> {
  List<Group> groups;

  @override
  void initState() {
    super.initState();
    groups = _computeGroups(widget.data.problemList.problems);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Container(child: _showAllProblems()));
  }

  /*
  Widget _showAllContests(Data data) {
    final contests = data.contestList.contests;
    return ListView.builder(
        itemCount: contests.length, itemBuilder: (context, i) => ContestWidget(data: data, contest: contests[i]));
  }
  */

  Widget _showAllProblems() {
    return ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            groups[index].isExpanded = !isExpanded;
          });
        },
        children: groups.map(_showGroup).toList());
  }

  ExpansionPanel _showGroup(Group group) {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Text(group.header),
          );
        },
        body: _showProblems(group.displayableProblems),
        isExpanded: group.isExpanded);
  }

  List<Group> _computeGroups(List<Problem> problems) {
    final Set<String> tags = problems.map((problem) => problem.tags).expand((tags) => tags).toSet();
    return [for (var tag in tags) GroupByProblemType(tag, problems, _getProblemFilter)];
  }

  bool _getProblemFilter(Problem problem) {
    return widget.data.submissions.getProblemStatus(problem) != ProblemStatus.untried;
  }

  Widget _showProblems(Iterable<Problem> problems) {
    final problemWidgets = problems.map((problem) => ProblemWidget.of(widget.data, problem)).toList();
    return Padding(
        padding: EdgeInsets.all(10),
        child: GridView.extent(
          maxCrossAxisExtent: 400.0,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 4,
          children: problemWidgets,
          shrinkWrap: true,
        ));
  }
}
