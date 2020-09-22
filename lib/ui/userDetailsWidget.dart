import 'package:cofoda/codeforcesAPI.dart';
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
  final Data _data;

  LoadedUserDetailsWidget({Key key, @required Data data, @required List<String> users})
      : _data = data,
        users = users,
        super(key: key);

  @override
  State<StatefulWidget> createState() => LoadedUserDetailsWidgetState();
}

class LoadedUserDetailsWidgetState extends State<LoadedUserDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(getTitle()),
        ),
        body: Text('TODO'));
  }

  String getTitle() => (widget.users[1] == null)
      ? 'Codeforces user: ${widget.users[0]}'
      : 'Codeforces users: ${widget.users[0]} VS ${widget.users[1]}';
}
