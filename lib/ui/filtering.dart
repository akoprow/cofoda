import 'package:dashforces/model/problem.dart';

abstract class Filter {
  const Filter();

  bool test(Problem problem);
}

class FilterByRating extends Filter {
  final int from, to;

  const FilterByRating(this.from, this.to);

  @override
  bool test(Problem problem) => problem.rating != null && problem.rating >= from && problem.rating <= to;
}

/*
class FilterByStatus extends Filter {
  final String user;
  final Set<ProblemStatus> acceptedStatus;
  final Data data;

  const FilterByStatus(this.user, this.data, this.acceptedStatus);

  @override
  bool test(Problem problem) {
    return acceptedStatus.contains(data.statusOfProblem(contest, user, problem));
  }
}
*/

class CompositeFilter extends Filter {
  final List<Filter> filters;

  const CompositeFilter(this.filters);

  @override
  bool test(Problem problem) {
    for (Filter filter in filters) {
      if (!filter.test(problem)) return false;
    }
    return true;
  }
}
