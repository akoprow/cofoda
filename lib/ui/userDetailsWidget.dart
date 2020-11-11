import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/ui/userProblemsByRatingChart.dart';
import 'package:dashforces/ui/userProblemsOverTimeChart.dart';
import 'package:flutter/material.dart';

class UserDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final body = TabBarView(
        children: [UserProblemsOverTimeChart(), UserProblemsByRatingChart()]);
    return MaterialApp(
        home: DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(tabs: [
                    Tab(text: 'Solved problems over time'),
                    Tab(text: 'Solved problems by rating')
                  ]),
                  title: withUsers((userData) => Text(_getTitle(userData))),
                ),
                body: body)));
  }

  String _getTitle(BothUsersData userData) {
    if (!userData.user.isPresent()) {
      return '';
    } else if (!userData.vsUser.isPresent()) {
      return 'Codeforces user: ${userData.user.handle}';
    } else {
      return 'Codeforces users: ${userData.user.handle} VS ${userData.vsUser.handle}';
    }
  }
}
