import 'dart:async';
import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashforces/model/contest.dart';
import 'package:dashforces/model/contestList.dart';
import 'package:dashforces/model/problem.dart';
import 'package:dashforces/model/submissions.dart';
import 'package:dashforces/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:synchronized/synchronized.dart';

enum Type { User, VsUser }

abstract class GenericUserData extends ChangeNotifier {
  static Duration userDataRefreshDuration = Duration(seconds: 15);

  final lock = Lock();

  String handle;
  bool isLoading = false;
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
    timer?.cancel();

    if (handle != null) {
      setLoading(true);
      print('Setting up timer for GenericUserDataProvider<$handle>');
      timer = Timer.periodic(userDataRefreshDuration, (_) {
        lock.synchronized(() async => await _checkIfRefreshNeeded());
      });
      FirebaseFirestore.instance
          .collection('users')
          .doc(newHandle)
          .snapshots()
          .listen((data) => lock.synchronized(() async => await _update(data)));
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
    if (event.exists) {
      submissions = AllUserSubmissions.fromFire(_contests, event.data());
      print('Got new data for user: $handle, submissions: ${submissions.size}');
    } else {
      print('No data for user: $handle');
      submissions = AllUserSubmissions.empty();
    }

    setLoading(false);
    _checkIfRefreshNeeded();
  }

  void _checkIfRefreshNeeded() async {
    if (isLoading) {
      return;
    }
    final client = http.Client();
    var refresh = false;
    final url =
        'https://codeforces.com/api/user.status?handle=${handle}&from=${submissions.size + 1}';
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
    setLoading(true);
    print('Refreshing user: $handle');
    final args = <String, dynamic>{'user': handle};
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
  Color get color => Colors.blue[400];
}

class VsUserData extends GenericUserData {
  VsUserData(ContestList contests) : super(contests);

  @override
  Type type() => Type.VsUser;

  @override
  Color get color => Colors.pink[400];
}
