import 'package:flutter/material.dart';
import 'package:shma_server/view_models/main.dart';
import 'package:shma_server/views/main.dart';

/// Service that holds all routing information of the navigators of the app.
class RouterService {
  /// Instance of the router service.
  static final RouterService _instance = RouterService._();

  /// GlobalKey of the state of the main navigator.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// Private constructor of the service.
  RouterService._();

  /// Returns the singleton instance of the [RouterService].
  static RouterService getInstance() {
    return _instance;
  }

  /// Routes of the main navigator.
  Map<String, Widget Function(BuildContext)> get routes {
    return {
      MainViewModel.route: (context) => const MainScreen(),
    };
  }

  /// Name of the initial route for the main navigation.
  String get initialRoute {
    return MainViewModel.route;
  }

  /// Routes of the nested navigator.
  Map<String, Route<dynamic>?> get nestedRoutes {
    return {
      // RecordsViewModel.route: PageRouteBuilder(
      //   pageBuilder: (context, animation1, animation2) => const RecordsScreen(),
      //   transitionDuration: const Duration(seconds: 0),
      // ),
    };
  }
}
