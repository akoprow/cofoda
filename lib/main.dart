import 'package:cofoda/ui/contestsDashboard.dart';
import 'package:cofoda/ui/problemsDashboard.dart';
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
  static const String problems = '/problems';
  static const String contests = '/contests';

  static const String userQueryParam = 'user';

  static Router router = Router();

  AppComponentState() {
    router = Router();
    router.define(root, handler: _problemsHandler());
    router.define(problems, handler: _problemsHandler());
    router.define(contests, handler: _contestsHandler());
  }

  Handler _problemsHandler() => Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        return ProblemsDashboardWidget(user: user);
      });

  Handler _contestsHandler() =>
      Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        return ContestsDashboardWidget(user: user);
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
