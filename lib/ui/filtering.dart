import 'package:cofoda/codeforcesAPI.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';

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

class FilterByStatus extends Filter {
  final Set<ProblemStatus> acceptedStatus;
  final Data data;

  const FilterByStatus(this.data, this.acceptedStatus);

  @override
  bool test(Problem problem) {
    return acceptedStatus.contains(data.statusOfProblem(problem));
  }
}

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
