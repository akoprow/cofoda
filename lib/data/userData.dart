import 'dart:async';
import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cofoda/model/contest.dart';
import 'package:cofoda/model/contestList.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum Type { User, VsUser }

abstract class GenericUserData extends ChangeNotifier {
  static Duration userDataRefreshDuration = Duration(seconds: 15);

  String handle;
  bool isLoading = false;
  bool gotFirebaseResponse = false;
  AllUserSubmissions submissions = AllUserSubmissions.empty();
  ContestList _contests;
  Timer timer;

  GenericUserData(this._contests);

  void setContests(ContestList contests) {
    _contests = contests;
    notifyListeners();
  }

  Color get color;

  bool isPresent() => handle != null;

  bool isReady() => isPresent() && !isLoading;

  void setHandle(String newHandle) {
    if (newHandle == null || handle == newHandle) {
      return;
    }

    handle = newHandle;
    gotFirebaseResponse = false;
    timer?.cancel();

    if (handle != null) {
      print('Setting up timer for GenericUserDataProvider<$handle>');
      _maybeRefreshUserData();
      timer = Timer.periodic(userDataRefreshDuration, (_) {
        _maybeRefreshUserData();
      });
      setLoading(true);
      FirebaseFirestore.instance
          .collection('users')
          .doc(newHandle)
          .snapshots()
          .listen(_update);
    } else {
      setLoading(false);
    }
  }

  Type type();

  Color problemStatusToColor(Contest contest, Problem problem,
      {int ratingLimit}) {
    final status =
        submissions.statusOfProblem(contest, problem, ratingLimit: ratingLimit);
    return statusToColor(status);
  }

  void _update(DocumentSnapshot event) {
    gotFirebaseResponse = true;
    if (event.exists) {
      submissions = AllUserSubmissions.fromFire(_contests, event.data());
      print('Got new data for user: $handle, submissions: ${submissions.size}');
      setLoading(false);
    } else {
      print('No data for user: $handle');
      setLoading(true);
      submissions = AllUserSubmissions.empty();
      _maybeRefreshUserData();
    }
  }

  void _maybeRefreshUserData() async {
    if (!gotFirebaseResponse) {
      return
    }
    final client = http.Client();
    var refresh = false;
    final url =
        'https://codeforces.com/api/user.status?handle=${handle}&from=${submissions
        .size + 1}';
    try {
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body) as Map<String, dynamic>;
        final missingSubmissions = body['result'] as List<dynamic>;
        print('URL: $url, missingSubmissions: ${missingSubmissions.length}');
        refresh = missingSubmissions.isNotEmpty;
      }
    } catch (e) {
      print('Error fetching data from: $url');
    } finally {
      client.close();
    }

    if (refresh) {
      await _refreshUserData();
    }
  }

  void _refreshUserData() async {
    print('Refreshing user: $handle');
    final args = <String, dynamic>{'user': handle};
    setLoading(true);
    await FirebaseFunctions.instance
        .httpsCallable('refreshUserData')
        .call<dynamic>(args);
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

class UserData extends GenericUserData {
  UserData(ContestList contests) : super(contests);

  @override
  Type type() => Type.User;

  @override
  Color get color => Colors.blue[200];
}

class VsUserData extends GenericUserData {
  VsUserData(ContestList contests) : super(contests);

  @override
  Type type() => Type.VsUser;

  @override
  Color get color => Colors.pink[200];
}
