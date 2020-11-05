import 'dart:async';
import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

enum Type { User, VsUser }

abstract class GenericUserDataProvider extends ChangeNotifier {
  static Duration userDataRefreshDuration = Duration(seconds: 15);

  String handle;
  bool isLoading = false;
  AllUserSubmissions submissions = AllUserSubmissions.empty();
  int numProcessed;
  Timer timer;

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

  Color problemStatusToColor(Problem problem, {int ratingLimit}) {
    final status =
        submissions.statusOfProblem(problem, ratingLimit: ratingLimit);
    return statusToColor(status);
  }

  void _update(DocumentSnapshot event) {
    if (event.exists) {
      print('Got new data for user: $handle');
      submissions = AllUserSubmissions.fromFire(event.data());
      numProcessed = _getNumProcessed(event.data());
      setLoading(false);
    } else {
      print('No data for user: $handle');
      setLoading(true);
      numProcessed = 0;
      _maybeRefreshUserData();
    }
  }

  void _maybeRefreshUserData() async {
    if (numProcessed == null) {
      return;
    }
    final client = http.Client();
    var refresh = false;
    final url =
        'https://codeforces.com/api/user.status?handle=${handle}&from=${numProcessed + 1 ?? 0}';
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

  int _getNumProcessed(Map<String, dynamic> data) {
    if (data == null || !data.containsKey('meta')) {
      return 0;
    } else {
      final meta = data['meta'] as Map<String, dynamic>;
      return meta['numProcessed'] as int;
    }
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

class UserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.User;

  @override
  Color get color => Colors.blue[300];
}

class VsUserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.VsUser;

  @override
  Color get color => Colors.brown[300];
}

class UsersData {
  final UserDataProvider user;
  final VsUserDataProvider vsUser;

  UsersData(this.user, this.vsUser);
}

Widget withUsers(Widget Function(UsersData users) f) {
  return Consumer2<UserDataProvider, VsUserDataProvider>(
      builder: (_, user, vsUser, __) => f(UsersData(user, vsUser)));
}
