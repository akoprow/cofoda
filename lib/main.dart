import 'package:cofoda/ui/contestDetailsWidget.dart';
import 'package:cofoda/ui/contestsListScreen.dart';
import 'package:cofoda/ui/problemsListScreen.dart';
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
  static const String userQueryParam = 'user';
  static const String contestIdParam = 'contestId';

  static const String routeRoot = '/';
  static const String routeProblems = '/problems';
  static const String routeAllContests = '/contests';
  static const String routeSingleContestPrefix = '/contest/';
  static const String routeSingleContest = '$routeSingleContestPrefix:$contestIdParam';

  static Router router = Router();

  AppComponentState() {
    router = Router();
    router.define(routeRoot, handler: _problemsHandler());
    router.define(routeProblems, handler: _problemsHandler());
    router.define(routeAllContests, handler: _allContestsHandler());
    router.define(routeSingleContest, handler: _singleContestsHandler());
  }

  Handler _problemsHandler() => Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        return ProblemsListScreenWidget(user: user);
      });

  Handler _allContestsHandler() => Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        return ContestsListScreen(user: user);
      });

  Handler _singleContestsHandler() =>
      Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String contestId = params[contestIdParam]?.first;
        return ContestDetailsWidget(user: user, contestId: contestId);
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
