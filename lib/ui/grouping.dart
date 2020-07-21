import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/ui/filtering.dart';

abstract class Group<T> {
  final List<Problem> matchingProblems;
  final List<Problem> displayableProblems;
  bool isExpanded;

  Group(List<Problem> allProblems, Filter problemFilter, bool Function(Problem) groupMembership)
      : this._fromMatchingProblems(allProblems.where(groupMembership).toList(), problemFilter);

  Group._fromMatchingProblems(List<Problem> matchingProblems, Filter problemFilter)
      : this._fromProblems(matchingProblems, matchingProblems.where(problemFilter.test).toList());

  Group._fromProblems(this.matchingProblems, this.displayableProblems) : isExpanded = displayableProblems.isNotEmpty;

  String get header;
}

class ProblemTypeGroup extends Group<String> implements Comparable<ProblemTypeGroup> {
  final String _tag;

  ProblemTypeGroup(this._tag, List<Problem> allProblems, Filter problemFilter)
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

  RatingGroup(this._rating, List<Problem> allProblems, Filter problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.rating == _rating);

  @override
  String get header => _rating == null ? 'no rating' : _rating.toString();

  @override
  int compareTo(RatingGroup other) =>
      _rating == null ? -1 : other._rating == null ? 1 : -_rating.compareTo(other._rating);
}

class ContestGroup extends Group<Contest> implements Comparable<ContestGroup> {
  final Contest _contest;

  ContestGroup(this._contest, List<Problem> allProblems, Filter problemFilter)
      : super(allProblems, problemFilter, (problem) => problem.contestId == _contest.id);

  @override
  String get header => _contest == null ? 'Unknown contest' : _contest.name;

  @override
  int compareTo(ContestGroup other) => -_contest.compareTo(other._contest);
}

abstract class Grouper<T> {
  const Grouper();

  Set<T> problemGroups(Problem problem);

  Group<T> createGroup(T tag, List<Problem> problems, Filter filter);
}

class GroupByProblemType extends Grouper<String> {
  const GroupByProblemType();

  @override
  Group<String> createGroup(String tag, List<Problem> problems, Filter filter) =>
      ProblemTypeGroup(tag, problems, filter);

  @override
  Set<String> problemGroups(Problem problem) => problem.tags.toSet();
}

class GroupByRating extends Grouper<int> {
  const GroupByRating();

  @override
  Group<int> createGroup(int tag, List<Problem> problems, Filter filter) => RatingGroup(tag, problems, filter);

  @override
  Set<int> problemGroups(Problem problem) => {problem.rating};
}

class GroupByContest extends Grouper<Contest> {
  final Data _data;

  const GroupByContest(this._data);

  @override
  Group<Contest> createGroup(Contest contest, List<Problem> problems, Filter filter) =>
      ContestGroup(contest, problems, filter);

  @override
  Set<Contest> problemGroups(Problem problem) => {problem.getContest(_data)};
}
