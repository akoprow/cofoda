import 'dart:async';
import 'dart:convert' as convert;

import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problem.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class _JsonData {
  final List<dynamic> problemsJson, contestsJson;

  _JsonData(this.problemsJson, this.contestsJson);

  static Future<_JsonData> load() async {
    final problemsResponse = await _fetchFrom('https://codeforces.com/api/problemset.problems');
    final problemsJson = problemsResponse['result']['problems'] as List<dynamic>;
    final contestsResponse = await _fetchFrom('https://codeforces.com/api/contest.list?gym=false');
    final contestsJson = contestsResponse['result'] as List<dynamic>;
    return _JsonData(problemsJson, contestsJson);
  }

  static Future<Map<String, dynamic>> _fetchFrom(String uri) async {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Request to $uri failed with status: ${response.statusCode}, ${response.body}');
      return null;
    }
  }
}

ContestList _buildContestList(_JsonData json) {
  final problems = json.problemsJson.map((dynamic json) => Problem.fromJson(json as Map<String, dynamic>)).toList();
  return ContestList.fromJson(json.contestsJson.toList(), problems);
}

class CodeforcesAPI {
  Future<ContestList> getAllContests() async {
    // TODO: Looks like we need to handle pagination?!
    return compute(_buildContestList, await _JsonData.load());
  }
}
