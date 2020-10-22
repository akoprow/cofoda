import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cofoda/model/problem.dart';
import 'package:cofoda/model/submissions.dart';
import 'package:cofoda/ui/problemWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

enum Type { User, VsUser }

abstract class GenericUserDataProvider extends ChangeNotifier {
  String handle;
  bool isLoading = true;
  AllUserSubmissions submissions = AllUserSubmissions.empty();

  bool present() => handle != null;

  void setHandle(String newHandle) {
    isLoading = true;
    handle = newHandle;

    if (handle != null) {
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
}

class UserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.User;
}

class VsUserDataProvider extends GenericUserDataProvider {
  @override
  Type type() => Type.VsUser;
}

Widget withUsers(
    Widget Function(UserDataProvider user, VsUserDataProvider vsUser) f) {
  return Consumer2<UserDataProvider, VsUserDataProvider>(
      builder: (_, user, vsUser, __) => f(user, vsUser));
}
