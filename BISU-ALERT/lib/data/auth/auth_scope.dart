import 'package:flutter/material.dart';

import 'auth_controller.dart';

/// Exposes the app-wide [AuthController] to the widget tree.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Reads the controller and rebuilds the caller whenever auth state changes.
  static AuthController of(BuildContext context) {
    final AuthScope? scope =
        context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found above this widget.');
    return scope!.notifier!;
  }

  /// Reads the controller without subscribing. Use inside callbacks.
  static AuthController read(BuildContext context) {
    final AuthScope? scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found above this widget.');
    return scope!.notifier!;
  }
}
