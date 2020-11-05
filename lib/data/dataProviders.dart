import 'package:cofoda/data/contestsData.dart';
import 'package:cofoda/data/userData.dart';
import 'package:cofoda/model/contestList.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

StreamProvider<ContestList> contestsProvider() =>
    StreamProvider(create: (_) => ContestsProvider.stream());

ChangeNotifierProxyProvider<ContestList, UserData> userDataProvider() =>
    ChangeNotifierProxyProvider<ContestList, UserData>(
        create: (_) => UserData(ContestList.empty()),
        update: (_, contests, userData) => userData..setContests(contests));

ChangeNotifierProxyProvider<ContestList, VsUserData> vsUserDataProvider() =>
    ChangeNotifierProxyProvider<ContestList, VsUserData>(
        create: (_) => VsUserData(ContestList.empty()),
        update: (_, contests, vsUserData) => vsUserData..setContests(contests));

List<SingleChildWidget> allDataProviders() =>
    [contestsProvider(), userDataProvider(), vsUserDataProvider()];

class BothUsersData {
  final UserData user;
  final VsUserData vsUser;

  BothUsersData(this.user, this.vsUser);
}

Widget withUsers(Widget Function(BothUsersData users) f) {
  return Consumer2<UserData, VsUserData>(
      builder: (_, user, vsUser, __) => f(BothUsersData(user, vsUser)));
}
