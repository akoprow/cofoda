
class Contest {
  final int id;
  final String name, type, phase;

  Contest({this.id, this.name, this.type, this.phase});

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      phase: json['phase'] as String);
}
