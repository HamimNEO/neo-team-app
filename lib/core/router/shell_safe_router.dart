import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Keeps one instance of each shell navigator when root pages are stacked.
class ShellSafeRouter extends GoRouter {
  ShellSafeRouter({
    required List<RouteBase> routes,
    required GoRouterRedirect redirect,
    required String Function(String) resolveLocation,
    required GlobalKey<NavigatorState> navigatorKey,
    required String initialLocation,
    required Listenable refreshListenable,
  })  : _resolveLocation = resolveLocation,
        super.routingConfig(
          routingConfig: _FixedRoutingConfig(
            RoutingConfig(routes: routes, redirect: redirect),
          ),
          navigatorKey: navigatorKey,
          initialLocation: initialLocation,
          refreshListenable: refreshListenable,
        );

  final String Function(String) _resolveLocation;

  bool _requiresRootPage(String destination, Object? extra) {
    final target = configuration.findMatch(destination, extra: extra);
    final current = routerDelegate.currentConfiguration.matches;
    for (final shell in target.matches.whereType<ShellRouteMatch>()) {
      final mounted = current.whereType<ShellRouteMatch>().where(
            (match) => match.route == shell.route,
          );
      if (mounted.isNotEmpty &&
          (mounted.length > 1 || current.last.route != shell.route)) {
        return true;
      }
    }
    return false;
  }

  String _pushLocation(String location, Object? extra) {
    final destination = _resolveLocation(location);
    return _requiresRootPage(destination, extra)
        ? Uri(path: '/stacked', queryParameters: {'screen': destination})
            .toString()
        : destination;
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    return super.push<T>(_pushLocation(location, extra), extra: extra);
  }

  @override
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) {
    return super
        .pushReplacement<T>(_pushLocation(location, extra), extra: extra);
  }

  @override
  Future<T?> replace<T>(String location, {Object? extra}) {
    return super.replace<T>(_pushLocation(location, extra), extra: extra);
  }
}

/// The route table is fixed; no notifier or listener resources are needed.
class _FixedRoutingConfig implements ValueListenable<RoutingConfig> {
  const _FixedRoutingConfig(this.value);

  @override
  final RoutingConfig value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
