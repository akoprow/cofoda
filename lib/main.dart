import 'package:cofoda/ui/contestDetailsWidget.dart';
import 'package:cofoda/ui/contestsListScreen.dart';
import 'package:cofoda/ui/problemsListScreen.dart';
import 'package:cofoda/ui/userDetailsWidget.dart';
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
  static const String vsUserQueryParam = 'vsUser';
  static const String contestIdParam = 'contestId';
  static const String ratingLimitParam = 'upsolveTo';
  static const String filterParam = 'filter';

  static const String routeRoot = '/';
  static const String routeUserPrefix = '/user/';
  static const String routeUser = '/user/:$userQueryParam';
  static const String routeProblems = '/problems';
  static const String routeAllContests = '/contests';
  static const String routeSingleContestPrefix = '/contest/';
  static const String routeSingleContest = '$routeSingleContestPrefix:$contestIdParam';

  static Router router = Router();

  AppComponentState() {
    router = Router();
    router.define(routeRoot, handler: _problemsHandler());
    router.define(routeUser, handler: _userHandler());
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
        final String vsUser = params[vsUserQueryParam]?.first;
        final String ratingLimit = params[ratingLimitParam]?.first;
        final String filter = params[filterParam]?.first;
        return ContestsListScreen(
            user: user,
            vsUser: vsUser,
            filter: filter,
            ratingLimit: ratingLimit == null ? null : int.parse(ratingLimit));
      });

  Handler _singleContestsHandler() =>
      Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String contestId = params[contestIdParam]?.first;
        return ContestDetailsWidget(users: [user], contestId: contestId);
      });

  Handler _userHandler() => Handler(handlerFunc: (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String vsUser = params[vsUserQueryParam]?.first;
        return UserDetailsWidget(users: [user, vsUser]);
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
