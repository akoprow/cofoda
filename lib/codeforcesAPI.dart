import 'dart:async';
import 'dart:convert' as convert;

import 'package:cofoda/model/contestList.dart';
import 'package:http/http.dart' as http;

class CodeforcesAPI {

  Future<ContestList> getAllContests() async {
    final uri = 'https://codeforces.com/api/contest.list?gym=false';
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final jsonResponse = convert.jsonDecode(response.body) as Map<String, dynamic>;
      print('Got JSON response');
      return ContestList.fromJson(jsonResponse['result'] as List<dynamic>);
    } else {
      print('Request to $uri failed with status: ${response.statusCode}, ${response.body}');
      return null;
    }
  }
}
