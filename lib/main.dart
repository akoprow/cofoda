import 'package:dashforces/data/dataProviders.dart';
import 'package:dashforces/data/userData.dart';
import 'package:dashforces/ui/contestsListScreen.dart';
import 'package:dashforces/ui/userDetailsWidget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluro/fluro.dart' as fluro;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Initialize(
      body: MultiProvider(providers: allDataProviders(), child: App())));
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

          // FirebaseFunctions.instance.useFunctionsEmulator(origin: 'http://localhost:5000');
          return Center(
              child: Container(
                  child: CircularProgressIndicator(), width: 32, height: 32));
        });
  }
}

class App extends StatelessWidget {
  static const String usersQueryParam = 'users';
  static const String contestIdParam = 'contestId';
  static const String ratingLimitParam = 'upsolveTo';
  static const String filterParam = 'filter';

  static const String routeRoot = '/';
  static const String routeUser = '/user';
  static const String routeProblems = '/problems';
  static const String routeAllContests = '/contests';
  static const String routeSingleContestPrefix = '/contest/';
  static const String routeSingleContest =
      '$routeSingleContestPrefix:$contestIdParam';

  static final router = fluro.FluroRouter();

  App() {
    router.define(routeRoot, handler: _allContestsHandler());
    router.define(routeAllContests, handler: _allContestsHandler());
    router.define(routeUser, handler: _userHandler());
/*
    router.define(routeProblems, handler: _problemsHandler());
    router.define(routeSingleContest, handler: _singleContestsHandler());
*/
  }

  void _setUsersFromParams(
      BuildContext context, Map<String, List<String>> params) {
    final String usersString = params[usersQueryParam]?.first;
    final userProvider = context.watch<UserData>();
    final vsUserProvider = context.watch<VsUserData>();

    if (usersString == null || usersString.isEmpty) {
      userProvider.setHandle(null);
      vsUserProvider.setHandle(null);
    } else {
      final users = usersString.split(',');
      if (users.isNotEmpty) {
        userProvider.setHandle(users[0]);
      }
      if (users.length > 1) {
        vsUserProvider.setHandle(users[1]);
      }
    }
  }

  fluro.Handler _allContestsHandler() => fluro.Handler(
          handlerFunc: (BuildContext ctx, Map<String, List<String>> params) {
        _setUsersFromParams(ctx, params);
        final String ratingLimit = params[ratingLimitParam]?.first;
        final String filter = params[filterParam]?.first;
        return ContestsListWidget(
            filter: filter,
            ratingLimit: ratingLimit == null ? null : int.parse(ratingLimit));
      });

  fluro.Handler _userHandler() => fluro.Handler(
          handlerFunc: (BuildContext ctx, Map<String, List<String>> params) {
        _setUsersFromParams(ctx, params);
        return UserDetailsWidget();
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
  */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Dashforces',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: router.generator);
  }
}
