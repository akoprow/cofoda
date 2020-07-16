import 'dart:async';
import 'dart:convert' as convert;

import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problem.dart';
import 'package:http/http.dart' as http;

class CodeforcesAPI {

  Future<ContestList> getAllContests() async {
    // TODO: Looks like we need to handle pagination!
    final problemsResponse = await _fetch('https://codeforces.com/api/problemset.problems');
    final problemsJson = problemsResponse['result']['problems'] as List<dynamic>;
    final problems = problemsJson.map((dynamic json) => Problem.fromJson(json as Map<String, dynamic>)).toList();

    final contests = await _fetch('https://codeforces.com/api/contest.list?gym=false');
    return ContestList.fromJson(contests['result'] as List<dynamic>, problems);
  }

  Future<Map<String, dynamic>> _fetch(String uri) async {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Request to $uri failed with status: ${response.statusCode}, ${response.body}');
      return null;
    }
  }
}
