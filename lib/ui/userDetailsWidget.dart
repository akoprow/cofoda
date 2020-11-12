import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/ui/scaffold.dart';
import 'package:dashforces/ui/userProblemsByRatingChart.dart';
import 'package:dashforces/ui/userProblemsOverTimeChart.dart';
import 'package:flutter/material.dart';

class UserDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) =>
      withUsers((userData) => show(ctx, userData));

  Widget show(BuildContext ctx, BothUsersData userData) {
    final tabs = TabBar(tabs: [
      Tab(text: 'Solved problems over time'),
      Tab(text: 'Solved problems by rating')
    ]);
    final body = TabBarView(
        children: [UserProblemsOverTimeChart(), UserProblemsByRatingChart()]);

    return DefaultTabController(
        length: 2,
        child: display(ctx, body,
            appBarBottom: tabs, screenTitle: _getTitle(userData)));
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
