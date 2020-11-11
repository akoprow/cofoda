import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/main.dart';
import 'package:flutter/material.dart';

Widget display(BuildContext ctx, Widget mainWidget,
    {RouteSettings settings, String screenTitle}) {
  screenTitle ??= 'dashforces';
  final appBar = AppBar(title: Text(screenTitle));
  return Scaffold(appBar: appBar, body: mainWidget, drawer: _Drawer());
}

class _Drawer extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => withUsers((users) => show(ctx, users));

  Widget show(BuildContext ctx, BothUsersData users) {
    final String suffix = _urlSuffixForUsers(users);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Column(children: <Widget>[
              Text('Welcome to dashforces',
                  textScaleFactor: 1.5, style: TextStyle(color: Colors.white)),
            ]),
            decoration: BoxDecoration(color: Colors.blue),
          ),
          menuItem(ctx, Icons.list_rounded, 'Contests',
              App.routeAllContests + suffix),
          menuItem(ctx, Icons.person, 'User', App.routeUser + suffix),
        ],
      ),
    );
  }

  static Widget menuItem(
      BuildContext context, IconData icon, String description, String routeName,
      {VoidCallback action}) {
    return ListTile(
        leading: Icon(icon),
        title: Text(description),
        onTap: () {
          // close drawer
          Navigator.pop(context);
          action?.call();
          Navigator.pushNamed(context, routeName);
        });
  }

  String _urlSuffixForUsers(BothUsersData users) {
    if (users.user.isPresent()) {
      if (users.vsUser.isPresent()) {
        return '?users=${users.user.handle},${users.vsUser.handle}';
      } else {
        return '?users=${users.user.handle}';
      }
    } else {
      return '';
    }
  }
}
