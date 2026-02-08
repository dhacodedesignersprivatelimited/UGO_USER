import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  refreshListenable: appStateNotifier,
  navigatorKey: appNavigatorKey,
  errorBuilder: (context, state) =>
  appStateNotifier.loggedIn ? HomeWidget() : LoginWidget(),
  routes: [
    FFRoute(
      name: '_initialize',
      path: '/',
      builder: (context, _) {
        // ✅ FIXED: Proper initialization logic
        print('🔵 Router Init - Logged In: ${appStateNotifier.loggedIn}, UserID: ${FFAppState().userid}');

        if (appStateNotifier.loggedIn) {
          // User authenticated with Firebase

          // Check if backend registration is complete (userid exists)
          if (FFAppState().userid != 0) {
            print('✅ User has backend ID → Going to Home');
            return HomeWidget();
          } else {
            print('⚠️ User authenticated but no backend ID → Go to Registration');
            // Extract mobile from Firebase phone number
            int? mobileInt;
            final phone = appStateNotifier.user?.phoneNumber;
            if (phone != null && phone.isNotEmpty) {
              String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length >= 10) {
                mobileInt = int.tryParse(digits.substring(digits.length - 10));
              } else {
                mobileInt = int.tryParse(digits);
              }
            }

            if (mobileInt != null) {
              return DetailspageWidget(mobile: mobileInt);
            } else {
              // Fallback: force logout if mobile can't be extracted
              return LoginWidget();
            }
          }
        }

        print('❌ User not logged in → Go to Login');
        return LoginWidget();
      },
    ),
    FFRoute(
      name: UgIntroWidget.routeName,
      path: UgIntroWidget.routePath,
      builder: (context, params) => UgIntroWidget(),
    ),
    FFRoute(
      name: LoginWidget.routeName,
      path: LoginWidget.routePath,
      builder: (context, params) => LoginWidget(),
    ),
    FFRoute(
      name: OtpverificationWidget.routeName,
      path: OtpverificationWidget.routePath,
      builder: (context, params) => OtpverificationWidget(
        mobile: params.getParam('mobile', ParamType.int),
      ),
    ),
    FFRoute(
      name: DetailspageWidget.routeName,
      path: DetailspageWidget.routePath,
      builder: (context, params) => DetailspageWidget(
        mobile: params.getParam('mobile', ParamType.int),
      ),
    ),
    FFRoute(
      name: PrivacypolicyWidget.routeName,
      path: PrivacypolicyWidget.routePath,
      builder: (context, params) => PrivacypolicyWidget(),
    ),
    FFRoute(
      name: NotificationAllowWidget.routeName,
      path: NotificationAllowWidget.routePath,
      builder: (context, params) => NotificationAllowWidget(
        mobile: params.getParam('mobile', ParamType.int),
        firstname: params.getParam('firstname', ParamType.String),
        lastname: params.getParam('lastname', ParamType.String),
        email: params.getParam('email', ParamType.String),
      ),
    ),
    FFRoute(
      name: LocationWidget.routeName,
      path: LocationWidget.routePath,
      builder: (context, params) => LocationWidget(
        mobile: params.getParam('mobile', ParamType.int),
        firstname: params.getParam('firstname', ParamType.String),
        lastname: params.getParam('lastname', ParamType.String),
        email: params.getParam('email', ParamType.String),
      ),
    ),
    FFRoute(
      name: ServiceoptionsWidget.routeName,
      path: ServiceoptionsWidget.routePath,
      builder: (context, params) => ServiceoptionsWidget(),
    ),
    FFRoute(
      name: HomeWidget.routeName,
      path: HomeWidget.routePath,
      requireAuth: true, // ✅ Require auth to access Home
      builder: (context, params) {
        // ✅ Additional check: redirect to registration if no userid
        if (FFAppState().userid == 0) {
          print('⚠️ Accessing Home without backend ID → Redirect to Details');
          // This shouldn't happen due to router logic, but safe fallback
          Future.microtask(() => context.go('/detailspage'));
        }
        return HomeWidget();
      },
    ),
    FFRoute(
      name: AccountManagementWidget.routeName,
      path: AccountManagementWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AccountManagementWidget(),
    ),
    FFRoute(
      name: SupportWidget.routeName,
      path: SupportWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SupportWidget(),
    ),
    FFRoute(
      name: WalletWidget.routeName,
      path: WalletWidget.routePath,
      requireAuth: true,
      builder: (context, params) => WalletWidget(),
    ),
    FFRoute(
      name: BalanceWidget.routeName,
      path: BalanceWidget.routePath,
      requireAuth: true,
      builder: (context, params) => BalanceWidget(),
    ),
    FFRoute(
      name: AutoBookWidget.routeName,
      path: AutoBookWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AutoBookWidget(
        rideId: params.getParam('rideId', ParamType.int),
      ),
    ),
    FFRoute(
      name: BikebookWidget.routeName,
      path: BikebookWidget.routePath,
      requireAuth: true,
      builder: (context, params) => BikebookWidget(),
    ),
    FFRoute(
      name: AvaliableOptionsWidget.routeName,
      path: AvaliableOptionsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AvaliableOptionsWidget(),
    ),
    FFRoute(
      name: ConformLocationWidget.routeName,
      path: ConformLocationWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ConformLocationWidget(),
    ),
    FFRoute(
      name: PlanYourRideWidget.routeName,
      path: PlanYourRideWidget.routePath,
      requireAuth: true,
      builder: (context, params) => PlanYourRideWidget(),
    ),
    FFRoute(
      name: ChooseDestinationWidget.routeName,
      path: ChooseDestinationWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ChooseDestinationWidget(),
    ),
    FFRoute(
      name: ScanToBookWidget.routeName,
      path: ScanToBookWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ScanToBookWidget(),
    ),
    FFRoute(
      name: HistoryWidget.routeName,
      path: HistoryWidget.routePath,
      requireAuth: true,
      builder: (context, params) => HistoryWidget(),
    ),
    FFRoute(
      name: SettingsPageWidget.routeName,
      path: SettingsPageWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SettingsPageWidget(),
    ),
    FFRoute(
      name: ProfileSettingWidget.routeName,
      path: ProfileSettingWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ProfileSettingWidget(),
    ),
    FFRoute(
      name: AddHomeWidget.routeName,
      path: AddHomeWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddHomeWidget(),
    ),
    FFRoute(
      name: AddOfficeWidget.routeName,
      path: AddOfficeWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddOfficeWidget(),
    ),
    FFRoute(
      name: SavedAddWidget.routeName,
      path: SavedAddWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SavedAddWidget(),
    ),
    FFRoute(
      name: AccessibilitySettingsWidget.routeName,
      path: AccessibilitySettingsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AccessibilitySettingsWidget(),
    ),
    FFRoute(
      name: HearingWidget.routeName,
      path: HearingWidget.routePath,
      requireAuth: true,
      builder: (context, params) => HearingWidget(),
    ),
    FFRoute(
      name: VisionWidget.routeName,
      path: VisionWidget.routePath,
      requireAuth: true,
      builder: (context, params) => VisionWidget(),
    ),
    FFRoute(
      name: CommunicationWidget.routeName,
      path: CommunicationWidget.routePath,
      requireAuth: true,
      builder: (context, params) => CommunicationWidget(),
    ),
    FFRoute(
      name: PushnotificationsWidget.routeName,
      path: PushnotificationsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => PushnotificationsWidget(),
    ),
    FFRoute(
      name: SafetypreferencesWidget.routeName,
      path: SafetypreferencesWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SafetypreferencesWidget(),
    ),
    FFRoute(
      name: TrustedcontactsWidget.routeName,
      path: TrustedcontactsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => TrustedcontactsWidget(),
    ),
    FFRoute(
      name: RidecheckWidget.routeName,
      path: RidecheckWidget.routePath,
      requireAuth: true,
      builder: (context, params) => RidecheckWidget(),
    ),
    FFRoute(
      name: TipautomaticallyWidget.routeName,
      path: TipautomaticallyWidget.routePath,
      requireAuth: true,
      builder: (context, params) => TipautomaticallyWidget(),
    ),
    FFRoute(
      name: ReservematchingWidget.routeName,
      path: ReservematchingWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ReservematchingWidget(),
    ),
    FFRoute(
      name: DriversnearbyalertsWidget.routeName,
      path: DriversnearbyalertsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => DriversnearbyalertsWidget(),
    ),
    FFRoute(
      name: ChooserideWidget.routeName,
      path: ChooserideWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ChooserideWidget(),
    ),
    FFRoute(
      name: CommuteAlertsWidget.routeName,
      path: CommuteAlertsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => CommuteAlertsWidget(),
    ),
    FFRoute(
      name: PaymentOptionsWidget.routeName,
      path: PaymentOptionsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => PaymentOptionsWidget(),
    ),
    FFRoute(
      name: AddPaymentWidget.routeName,
      path: AddPaymentWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddPaymentWidget(),
    ),
    FFRoute(
      name: VoucherWidget.routeName,
      path: VoucherWidget.routePath,
      requireAuth: true,
      builder: (context, params) => VoucherWidget(),
    ),
    FFRoute(
      name: WalletPasswordWidget.routeName,
      path: WalletPasswordWidget.routePath,
      requireAuth: true,
      builder: (context, params) => WalletPasswordWidget(),
    ),
    FFRoute(
      name: AddCardsWidget.routeName,
      path: AddCardsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddCardsWidget(),
    ),
    FFRoute(
      name: DriverDetailsWidget.routeName,
      path: DriverDetailsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => DriverDetailsWidget(
        driverId: params.getParam('driverId', ParamType.int),
        vehicleType: params.getParam('vehicleType', ParamType.int),
        baseFare: params.getParam('baseFare', ParamType.double),
        baseKmStart: params.getParam('baseKmStart', ParamType.double),
        baseKmEnd: params.getParam('baseKmEnd', ParamType.double),
        pricePerKm: params.getParam('pricePerKm', ParamType.double),
      ),
    ),
    FFRoute(
      name: MessagesWidget.routeName,
      path: MessagesWidget.routePath,
      requireAuth: true,
      builder: (context, params) => MessagesWidget(),
    ),
    FFRoute(
      name: LanguageWidget.routeName,
      path: LanguageWidget.routePath,
      requireAuth: true,
      builder: (context, params) => LanguageWidget(),
    ),
    FFRoute(
      name: AccountSupportWidget.routeName,
      path: AccountSupportWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AccountSupportWidget(),
    ),
    FFRoute(
      name: SupportRideWidget.routeName,
      path: SupportRideWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SupportRideWidget(),
    ),
    FFRoute(
      name: RideOverviewWidget.routeName,
      path: RideOverviewWidget.routePath,
      requireAuth: true,
      builder: (context, params) => RideOverviewWidget(),
    ),
    FFRoute(
      name: FindLostItemsWidget.routeName,
      path: FindLostItemsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => FindLostItemsWidget(),
    ),
    FFRoute(
      name: ReportIssuesWidget.routeName,
      path: ReportIssuesWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ReportIssuesWidget(),
    ),
    FFRoute(
      name: CustomerSuportWidget.routeName,
      path: CustomerSuportWidget.routePath,
      requireAuth: true,
      builder: (context, params) => CustomerSuportWidget(),
    ),
    FFRoute(
      name: BookSucessfullWidget.routeName,
      path: BookSucessfullWidget.routePath,
      requireAuth: true,
      builder: (context, params) => BookSucessfullWidget(),
    ),
    FFRoute(
      name: CancelRideWidget.routeName,
      path: CancelRideWidget.routePath,
      requireAuth: true,
      builder: (context, params) => CancelRideWidget(),
    ),
    FFRoute(
      name: AddStopWidget.routeName,
      path: AddStopWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddStopWidget(),
    ),
    FFRoute(
      name: AddStopsWidget.routeName,
      path: AddStopsWidget.routePath,
      requireAuth: true,
      builder: (context, params) => AddStopsWidget(),
    ),
    FFRoute(
      name: PasswordcardWidget.routeName,
      path: PasswordcardWidget.routePath,
      requireAuth: true,
      builder: (context, params) => PasswordcardWidget(),
    ),
    FFRoute(
      name: ReviewWidget.routeName,
      path: ReviewWidget.routePath,
      requireAuth: true,
      builder: (context, params) => ReviewWidget(),
    ),
    FFRoute(
      name: RidecompleteWidget.routeName,
      path: RidecompleteWidget.routePath,
      requireAuth: true,
      builder: (context, params) => RidecompleteWidget(
        driverDetails: params.getParam('driverDetails', ParamType.JSON),
      ),
    ),
    FFRoute(
      name: SetLocationWidget.routeName,
      path: SetLocationWidget.routePath,
      requireAuth: true,
      builder: (context, params) => SetLocationWidget(),
    )
  ].map((r) => r.toRoute(appStateNotifier)).toList(),
);

// ... rest of your extension code remains the same ...
extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
    entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!)),
  );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
      String name,
      bool mounted, {
        Map<String, String> pathParameters = const <String, String>{},
        Map<String, String> queryParameters = const <String, String>{},
        Object? extra,
        bool ignoreRedirect = false,
      }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );

  void pushNamedAuth(
      String name,
      bool mounted, {
        Map<String, String> pathParameters = const <String, String>{},
        Map<String, String> queryParameters = const <String, String>{},
        Object? extra,
        bool ignoreRedirect = false,
      }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );

  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  bool get isEmpty =>
      state.allParams.isEmpty ||
          (state.allParams.length == 1 &&
              state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
    state.allParams.entries.where(isAsyncParam).map(
          (param) async {
        final doc = await asyncParams[param.key]!(param.value)
            .onError((_, __) => null);
        if (doc != null) {
          futureParamValues[param.key] = doc;
          return true;
        }
        return false;
      },
    ),
  ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
      String paramName,
      ParamType type, {
        bool isList = false,
      }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    if (param is! String) {
      return param;
    }
    return deserializeParam<T>(param, type, isList);
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
    name: name,
    path: path,
    redirect: (context, state) {
      if (appStateNotifier.shouldRedirect) {
        final redirectLocation = appStateNotifier.getRedirectLocation();
        appStateNotifier.clearRedirectLocation();
        return redirectLocation;
      }

      if (requireAuth && !appStateNotifier.loggedIn) {
        appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
        return '/login';
      }
      return null;
    },
    pageBuilder: (context, state) {
      fixStatusBarOniOS16AndBelow(context);
      final ffParams = FFParameters(state, asyncParams);
      final page = ffParams.hasFutures
          ? FutureBuilder(
        future: ffParams.completeFutures(),
        builder: (context, _) => builder(context, ffParams),
      )
          : builder(context, ffParams);
      final child = appStateNotifier.loading
          ? Container(
        color: Color(0xFFFF7B10),
        child: Image.asset(
          'assets/images/logo--_1.png',
          fit: BoxFit.none,
        ),
      )
          : page;

      final transitionInfo = state.transitionInfo;
      return transitionInfo.hasTransition
          ? CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: transitionInfo.duration,
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
            PageTransition(
              type: transitionInfo.transitionType,
              duration: transitionInfo.duration,
              reverseDuration: transitionInfo.duration,
              alignment: transitionInfo.alignment,
              child: child,
            ).buildTransitions(
              context,
              animation,
              secondaryAnimation,
              child,
            ),
      )
          : MaterialPage(key: state.pageKey, child: child);
    },
    routes: routes,
  );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
    value: RootPageContext(true, errorRoute),
    child: child,
  );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
