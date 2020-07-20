import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/grouping.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/*
TODO:
- Getting setup from URL params.
- I'm feeling randomly option
- Add filtering options
- Add sorting options
- Problems with no grouping
- https://www.buymeacoffee.com/ widget?
*/

class DashboardWidget extends StatelessWidget {
  final String user;

  DashboardWidget({this.user});

  @override
  Widget build(BuildContext context) =>
      showFuture(CodeforcesAPI().load(user: user), (Data data) => LoadedDashboardWidget(data: data));
}

class LoadedDashboardWidget extends StatefulWidget {
  final Data data;

  const LoadedDashboardWidget({Key key, this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoadedDashboardWidgetState();
  }
}

class LoadedDashboardWidgetState extends State<LoadedDashboardWidget> {
  static const showEmptyGroups = false;
  
  List<Group> groups;
  int displayableProblemsNum;

  @override
  void initState() {
    super.initState();
    groups = _computeGroups(widget.data.problemList.problems, _getProblemGrouper(), showEmptyGroups: showEmptyGroups);
    displayableProblemsNum = widget.data.problemList.problems.where(_getProblemFilter).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    final explanation = Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Showing $displayableProblemsNum / ${widget.data.problemList.problems.length} problems in ${groups
              .length} groups',
          textAlign: TextAlign.left,
        )
    );
    final problems = Scrollbar(
        child: ListView.builder(
          itemCount: 2 * groups.length,
          itemBuilder: (context, i) => (i % 2 == 0) ? _showGroupHeader(groups[i ~/ 2]) : _showGroupBody(groups[i ~/ 2]),
        ));
    return Column(children: [explanation, Expanded(child: problems)], crossAxisAlignment: CrossAxisAlignment.start);
  }

  Widget _showGroupHeader(Group group) {
    return Card(
      color: group.isExpanded ? Colors.white : Colors.grey[200],
      child: ListTile(
        title: Text(group.header),
        subtitle: Text('[${group.displayableProblems.length} / ${group.matchingProblems.length}]'),
        trailing: Text(group.isExpanded || group.displayableProblems.isEmpty ? '' : '(click to expand)'),
        onTap: () {
          if (group.displayableProblems.isNotEmpty) {
            setState(() {
              group.isExpanded = !group.isExpanded;
            });
          }
        },
      ),
    );
  }

  Widget _showGroupBody(Group group) {
    if (group.isExpanded && group.displayableProblems.isNotEmpty) {
      return _showProblems(group.displayableProblems);
    } else {
      return Container();
    }
  }

  List<Group> _computeGroups<T>(List<Problem> problems, Grouper<T> grouper, {bool showEmptyGroups}) {
    final Set<T> tags = problems.map((problem) => grouper.problemGroups(problem)).expand((tags) => tags).toSet();
    final groups = [for (var tag in tags) grouper.createGroup(tag, problems, _getProblemFilter)];
    if (!showEmptyGroups) {
      groups.removeWhere((group) => group.displayableProblems.isEmpty);
    }
    groups.sort();
    return groups;
  }

  bool _getProblemFilter(Problem problem) {
    return widget.data.submissions.getProblemStatus(problem) != ProblemStatus.untried;
  }

  Grouper<Contest> _getProblemGrouper() => GroupByContest(widget.data);

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
