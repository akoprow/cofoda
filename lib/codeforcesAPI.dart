import 'dart:async';
import 'dart:convert' as convert;

import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problemList.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Data {
  final ProblemList problemList;
  final ContestList contestList;

  Data(this.problemList, this.contestList);
}

Future<List<dynamic>> _loadProblemsJson() async {
  final problemsResponse = await _fetchFrom('https://codeforces.com/api/problemset.problems');
    return problemsResponse['result']['problems'] as List<dynamic>;
}

Future<List<dynamic>> _loadContestsJson() async {
    final contestsResponse = await _fetchFrom('https://codeforces.com/api/contest.list?gym=false');
    return contestsResponse['result'] as List<dynamic>;
  }

Future<Map<String, dynamic>> _fetchFrom(String uri) async {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return convert.jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Request to $uri failed with status: ${response.statusCode}, ${response.body}');
      return null;
    }
  }

Future<Data> _loadData(int i) async {
  final problems = ProblemList.fromJson(await _loadProblemsJson());
  final contests = ContestList.fromJson(await _loadContestsJson(), problems);
  return Data(problems, contests);
}

class CodeforcesAPI {
  Future<Data> load() async {
    // TODO: Looks like we need to handle pagination?!
    return compute(_loadData, null);
  }
}
