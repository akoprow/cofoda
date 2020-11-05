import 'dart:core';

import 'package:cofoda/data/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/ui/filtering.dart';
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
- Add sorting options
- Problems with no grouping
- https://www.buymeacoffee.com/ widget?
*/

class ProblemsListScreenWidget extends StatelessWidget {
  final String user;

  ProblemsListScreenWidget({this.user});

  @override
  Widget build(BuildContext context) {
    final body = showFuture(
        CodeforcesAPI().load(users: [user]), (Data data) => LoadedProblemsListWidget(user: user, data: data));
    return Scaffold(appBar: AppBar(title: Text('CoFoDa: CodeForces Dashboard')), body: body);
  }
}

class LoadedProblemsListWidget extends StatefulWidget {
  final String user;
  final Data data;

  const LoadedProblemsListWidget({Key key, @required this.user, @required this.data}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return LoadedProblemsListWidgetState();
  }
}

class LoadedProblemsListWidgetState extends State<LoadedProblemsListWidget> {
  static const showEmptyGroups = false;

  List<Group> groups;
  int displayableProblemsNum;

  @override
  void initState() {
    super.initState();
    groups = _computeGroups(widget.data.problemList.problems, _getProblemGrouper(), showEmptyGroups: showEmptyGroups);
    displayableProblemsNum = widget.data.problemList.problems.where(_getProblemFilter().test).toList().length;
  }

  Problem _randomProblem() {
    final allProblems =
        groups.map((group) => group.displayableProblems).expand((problems) => problems).toSet().toList();
    allProblems.shuffle();
    return allProblems.first;
  }

  @override
  Widget build(BuildContext context) {
    final randomly = OutlineButton.icon(
        label: Text("I'm feeling randomly"), onPressed: () => _randomProblem().open(), icon: Icon(Icons.shuffle));
    final explanation = Text(
      'Showing $displayableProblemsNum / ${widget.data.problemList.problems.length} problems in ${groups
          .length} groups',
      textAlign: TextAlign.left,
    );
    final topBar = Padding(padding: EdgeInsets.all(10), child: Row(children: [randomly, Spacer(), explanation]));
    final problems = Scrollbar(
        child: ListView.builder(
          itemCount: 2 * groups.length,
          itemBuilder: (context, i) => (i % 2 == 0) ? _showGroupHeader(groups[i ~/ 2]) : _showGroupBody(groups[i ~/ 2]),
        ));
    return Column(children: [topBar, Expanded(child: problems)], crossAxisAlignment: CrossAxisAlignment.start);
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
    final groups = [for (var tag in tags) grouper.createGroup(tag, problems, _getProblemFilter())];
    if (!showEmptyGroups) {
      groups.removeWhere((group) => group.displayableProblems.isEmpty);
    }
    groups.sort();
    return groups;
  }

  Filter _getProblemFilter() =>
      CompositeFilter([
        FilterByRating(1400, 1600),
//        FilterByStatus(widget.user, widget.data, {ProblemStatus.untried})
      ]);

  Grouper<String> _getProblemGrouper() => GroupByProblemType();

  Widget _showProblems(Iterable<Problem> problems) {
    final problemWidgets = problems
        .map(
            (problem) => ProblemWidget(widget.user, widget.data, null, problem))
        .toList();
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
