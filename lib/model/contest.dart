
class Contest {
  final int id;
  final String name, type, phase;

  Contest({this.id, this.name, this.type, this.phase});

  factory Contest.fromJson(Map<String, dynamic> json) =>
      Contest(id: json['id'], name: json['name'], type: json['type'], phase: json['phase']);
}
