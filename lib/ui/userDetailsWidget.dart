import 'package:cofoda/data/codeforcesAPI.dart';
import 'package:cofoda/ui/userProblemsByRatingChart.dart';
import 'package:cofoda/ui/userProblemsOverTimeChart.dart';
import 'package:cofoda/ui/utils.dart';
import 'package:flutter/material.dart';

class UserDetailsWidget extends StatelessWidget {
  final List<String> users;

  UserDetailsWidget({this.users});

  @override
  Widget build(BuildContext context) =>
      showFuture(CodeforcesAPI().load(users: users), (Data data) => LoadedUserDetailsWidget(data: data, users: users));
}

class LoadedUserDetailsWidget extends StatefulWidget {
  final List<String> users;
  final Data data;

  LoadedUserDetailsWidget({Key key, @required Data data, @required List<String> users})
      : data = data,
        users = users,
        super(key: key);

  @override
  State<StatefulWidget> createState() => LoadedUserDetailsWidgetState();
}

class LoadedUserDetailsWidgetState extends State<LoadedUserDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    final body = TabBarView(children: [
      UserProblemsOverTimeChart(users: widget.users, data: widget.data),
      UserProblemsByRatingChart(users: widget.users, data: widget.data)
    ]);
    return MaterialApp(
        home: DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                  bottom:
                      TabBar(tabs: [Tab(text: 'Solved problems over time'), Tab(text: 'Solved problems by rating')]),
                  title: Text(getTitle()),
                ),
                body: body)));
  }

  String getTitle() => (widget.users[1] == null)
      ? 'Codeforces user: ${widget.users[0]}'
      : 'Codeforces users: ${widget.users[0]} VS ${widget.users[1]}';
}
