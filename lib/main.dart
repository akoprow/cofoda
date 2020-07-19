import 'package:cofoda/ui/dashboard.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(AppComponent());
}

class AppComponent extends StatefulWidget {
  @override
  State createState() => AppComponentState();
}

class AppComponentState extends State<AppComponent> {
  static const String root = '/';
  static const String dashboard = '/dashboard';

  static const String userQueryParam = 'user';

  static Router router = Router();

  AppComponentState() {
    router = Router();
    router.define(root, handler: _rootHandler());
    router.define(dashboard, handler: _rootHandler());
  }

  Handler _rootHandler() => Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        print('User: $user');
        return Page(body: DashboardWidget(user: user));
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CoFoDa',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: router.generator);
  }
}

class Page extends StatelessWidget {
  final Widget body;

  const Page({Key key, this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('CoFoDa: CodeForces Dashboard')), body: body);
}
