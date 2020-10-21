import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

enum Type { User, VsUser }

abstract class GenericUserDataProvider extends ChangeNotifier {
  String handle;
  bool isLoading;

  void setHandle(String newHandle) {
    isLoading = true;
    handle = newHandle;

    FirebaseFirestore.instance
        .collection('users')
        .doc(newHandle)
        .snapshots()
        .listen(_update);
  }

  Type type();

  void _update(DocumentSnapshot event) {
    isLoading = false;
    event.data();

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
