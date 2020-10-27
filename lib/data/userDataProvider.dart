import 'dart:async';
import 'dart:convert' as convert;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

enum Type { User, VsUser }

abstract class GenericUserDataProvider extends ChangeNotifier {
  static Duration userDataRefreshDuration = Duration(seconds: 15);

  String handle;
  bool isLoading = true;
  AllUserSubmissions submissions = AllUserSubmissions.empty();
  int numProcessed;
  Timer timer;
  DateTime lastRefresh;

  bool present() => handle != null;

  void setHandle(String newHandle) {
    if (newHandle == null || handle == newHandle) {
      return;
    }

    isLoading = true;
    lastRefresh = null;
    handle = newHandle;
    timer?.cancel();

    if (handle != null) {
      print('Setting up timer for GenericUserDataProvider<$handle>');
      maybeRefreshUserData();
      timer = Timer.periodic(userDataRefreshDuration, (_) {
        maybeRefreshUserData();
      });
      FirebaseFirestore.instance
          .collection('users')
          .doc(newHandle)
          .snapshots()
          .listen(_update);
    }
  }

  Type type();

  Color problemStatusToColor(Problem problem, {int ratingLimit}) {
    final status =
        submissions.statusOfProblem(problem, ratingLimit: ratingLimit);
    return statusToColor(status);
  }

  void _update(DocumentSnapshot event) {
    isLoading = false;
    submissions = AllUserSubmissions.fromFire(event.data());
    numProcessed = _getNumProcessed(event.data());
    notifyListeners();
  }

  void maybeRefreshUserData() async {
    final client = http.Client();
    var refresh = false;
    try {
      final url =
          'https://codeforces.com/api/user.status?handle=${handle}&from=${numProcessed + 1 ?? 0}';
      final response = await client.get(url);
      if (response.statusCode == 200) {
        final body = convert.jsonDecode(response.body) as Map<String, dynamic>;
        final missingSubmissions = body['result'] as List<dynamic>;
        refresh = missingSubmissions.isNotEmpty;
      }
    } finally {
      client.close();
    }

    if (refresh) {
      await refreshUserData();
    }
  }

  void refreshUserData() async {
    print('Refreshing user: $handle');
    final args = <String, dynamic>{'user': handle};
    await FirebaseFunctions.instance
        .httpsCallable('refreshUserData')
        .call<dynamic>(args);
  }

  int _getNumProcessed(Map<String, dynamic> data) {
    final meta = data['meta'] as Map<String, dynamic>;
    return meta['numProcessed'] as int;
  }
}

class UserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.User;
}

class VsUserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.VsUser;
}

Widget withUsers(Widget Function(UserDataProvider user, VsUserDataProvider vsUser) f) {
  return Consumer2<UserDataProvider, VsUserDataProvider>(
      builder: (_, user, vsUser, __) => f(user, vsUser));
}
