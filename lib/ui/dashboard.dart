import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardWidget extends StatelessWidget {
  final String user;

  DashboardWidget({this.user});

  @override
  Widget build(BuildContext context) =>
      showFuture(CodeforcesAPI().load(user: user), (Data data) => LoadedDashboardWidget(data: data));
}

abstract class Group<T> {
  final List<Problem> matchingProblems;
  final List<Problem> displayableProblems;
  bool isExpanded;

  Group(List<Problem> allProblems, bool Function(Problem) problemFilter, bool Function(Problem) groupMembership)
      : this._fromMatchingProblems(allProblems.where(groupMembership).toList(), problemFilter);

  Group._fromMatchingProblems(List<Problem> matchingProblems, bool Function(Problem) problemFilter)
      : this._fromProblems(matchingProblems, matchingProblems.where(problemFilter).toList());

  Group._fromProblems(this.matchingProblems, this.displayableProblems) : isExpanded = displayableProblems.isNotEmpty;

  String get header;
}

class GroupByProblemType extends Group<String> implements Comparable<GroupByProblemType> {
  final String _tag;

  GroupByProblemType(this._tag, List<Problem> allProblems, bool Function(Problem) problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.tags.contains(_tag));

  @override
  String get header => _tag;

  @override
  int compareTo(GroupByProblemType other) {
    return -matchingProblems.length.compareTo(other.matchingProblems.length);
  }
}

class LoadedDashboardWidget extends StatefulWidget {
  final Data data;

  const LoadedDashboardWidget({Key key, this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoadedDashboardWidgetState();
}

class LoadedDashboardWidgetState extends State<LoadedDashboardWidget> {
  List<Group> groups;

  @override
  void initState() {
    super.initState();
    groups = _computeGroups(widget.data.problemList.problems);
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        child: ListView.builder(
      itemCount: 2 * groups.length,
      itemBuilder: (context, i) => (i % 2 == 0) ? _showGroupHeader(groups[i ~/ 2]) : _showGroupBody(groups[i ~/ 2]),
    ));
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

  List<Group> _computeGroups(List<Problem> problems) {
    final Set<String> tags = problems.map((problem) => problem.tags).expand((tags) => tags).toSet();
    final groups = [for (var tag in tags) GroupByProblemType(tag, problems, _getProblemFilter)];
    groups.sort();
    return groups;
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
