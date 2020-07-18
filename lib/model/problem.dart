class Problem implements Comparable<Problem> {
  final int contestId, rating;
  final String index, name, type;
  final List<String> tags;

  Problem({this.contestId, this.index, this.name, this.type, this.rating, this.tags});

  String get id => '$contestId$index';

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
      contestId: json['contestId'] as int,
      index: json['index'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      rating: json.containsKey('rating') ? json['rating'] as int : null,
      tags: (json['tags'] as List<dynamic>).cast<String>());

  @override
  int compareTo(Problem other) => index.compareTo(other.index);
}
