import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum Type { User, VsUser }

abstract class GenericUserDataProvider extends ChangeNotifier {
  static Duration userDataRefreshDuration = Duration(seconds: 15);

  String handle;
  bool isLoading = true;
  AllUserSubmissions submissions = AllUserSubmissions.empty();
  Timer timer;
  DateTime lastRefresh;

  bool present() => handle != null;

  void setHandle(String newHandle) {
    if (handle == newHandle) {
      return;
    }

    isLoading = true;
    lastRefresh = null;
    handle = newHandle;
    timer?.cancel();

    if (handle != null) {
      userDataRefresh();
      timer = Timer.periodic(userDataRefreshDuration, (_) {
        userDataRefresh();
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
    notifyListeners();
  }

  void userDataRefresh() {
    final now = DateTime.now();
    final nextRefresh = lastRefresh?.add(userDataRefreshDuration);

    if (nextRefresh == null || !nextRefresh.isAfter(now)) {
      print('Refreshing user: $handle [lastRefresh: $lastRefresh, now: $now]');
      final args = <String, dynamic>{'user': handle};
      FirebaseFunctions.instance
          .httpsCallable('refreshUserData')
          .call<dynamic>(args);
      lastRefresh = now;
    }
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
