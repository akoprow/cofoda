import 'package:cofoda/ui/contestsListScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluro/fluro.dart' as fluro;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Initialize(body: AppComponent()));
}

class Initialize extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  final Widget body;

  Initialize({Key key, @required this.body}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(':(');
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return body;
          }

          return Center(
              child: Container(
                  child: CircularProgressIndicator(), width: 32, height: 32));
        });
  }
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
  static const String routeSingleContest =
      '$routeSingleContestPrefix:$contestIdParam';

  static final router = fluro.FluroRouter();

  AppComponentState() {
    router.define(routeRoot, handler: _allContestsHandler());
    router.define(routeAllContests, handler: _allContestsHandler());
/*
    router.define(routeUser, handler: _userHandler());
    router.define(routeProblems, handler: _problemsHandler());
    router.define(routeSingleContest, handler: _singleContestsHandler());
*/
  }

  fluro.Handler _allContestsHandler() => fluro.Handler(handlerFunc:
          (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String vsUser = params[vsUserQueryParam]?.first;
        final String ratingLimit = params[ratingLimitParam]?.first;
        final String filter = params[filterParam]?.first;
        return ContestsListWidget(
            user: user,
            vsUser: vsUser,
            filter: filter,
            ratingLimit: ratingLimit == null ? null : int.parse(ratingLimit));
      });

  /*
  fluro.Handler _problemsHandler() => fluro.Handler(handlerFunc:
          (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        return ProblemsListScreenWidget(user: user);
      });

  fluro.Handler _singleContestsHandler() => fluro.Handler(handlerFunc:
          (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String contestId = params[contestIdParam]?.first;
        return ContestDetailsWidget(users: [user], contestId: contestId);
      });

  fluro.Handler _userHandler() => fluro.Handler(handlerFunc:
          (BuildContext context, Map<String, List<String>> params) {
        final String user = params[userQueryParam]?.first;
        final String vsUser = params[vsUserQueryParam]?.first;
        return UserDetailsWidget(users: [user, vsUser]);
      });
  */

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
