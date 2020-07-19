import 'dart:core';

import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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

class ProblemTypeGroup extends Group<String> implements Comparable<ProblemTypeGroup> {
  final String _tag;

  ProblemTypeGroup(this._tag, List<Problem> allProblems, bool Function(Problem) problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.tags.contains(_tag));

  @override
  String get header => _tag;

  @override
  int compareTo(ProblemTypeGroup other) {
    return -matchingProblems.length.compareTo(other.matchingProblems.length);
  }
}

class RatingGroup extends Group<int> implements Comparable<RatingGroup> {
  final int _rating;

  RatingGroup(this._rating, List<Problem> allProblems, bool Function(Problem) problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.rating == _rating);

  @override
  String get header => _rating == null ? 'no rating' : _rating.toString();

  @override
  int compareTo(RatingGroup other) =>
      _rating == null ? -1 : other._rating == null ? 1 : -_rating.compareTo(other._rating);
}

abstract class Grouper<T> {
  const Grouper();

  Set<T> problemGroups(Problem problem);

  Group<T> createGroup(T tag, List<Problem> problems, bool Function(Problem problem) filter);
}

class GroupByProblemType extends Grouper<String> {
  const GroupByProblemType();

  @override
  Group<String> createGroup(String tag, List<Problem> problems, bool Function(Problem problem) filter) =>
      ProblemTypeGroup(tag, problems, filter);

  @override
  Set<String> problemGroups(Problem problem) => problem.tags.toSet();
}

class GroupByRating extends Grouper<int> {
  const GroupByRating();

  @override
  Group<int> createGroup(int tag, List<Problem> problems, bool Function(Problem problem) filter) =>
      RatingGroup(tag, problems, filter);

  @override
  Set<int> problemGroups(Problem problem) => {problem.rating};
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
  static const groupper = GroupByRating();

  List<Group> groups;
  int displayableProblemsNum;

  @override
  void initState() {
    super.initState();
    groups = _computeGroups(widget.data.problemList.problems, groupper);
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

  List<Group> _computeGroups<T>(List<Problem> problems, Grouper<T> grouper) {
    final Set<T> tags = problems.map((problem) => grouper.problemGroups(problem)).expand((tags) => tags).toSet();
    final groups = [for (var tag in tags) grouper.createGroup(tag, problems, _getProblemFilter)];
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
