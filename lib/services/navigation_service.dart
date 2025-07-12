import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  void removeAndNavigateToRoute(String route) {
    navigatorKey.currentState?.popAndPushNamed(route);
  }

  void navigateToRoute(String route) {
    navigatorKey.currentState?.pushNamed(route);
  }

  void navigateToPage(Widget page) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (BuildContext context) => page),
    );
  }

  void goBack() {
    navigatorKey.currentState?.pop();
  }

  void showSnackBar(String message) {
    if (navigatorKey.currentState != null &&
        navigatorKey.currentState!.context != null) {
      ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }
}
