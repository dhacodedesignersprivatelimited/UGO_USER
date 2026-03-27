import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';
import 'backend/firebase/firebase_config.dart';
import 'backend/api_requests/api_calls.dart';
import 'config/payment_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'flutter_flow/firebase_app_check_util.dart';
import 'notifications/fcm_service.dart';

// Orange theme colors
const _orangePrimary = Color(0xFFFF7B10);
const _orangeSecondary = Color(0xFFFF9F4D);
const _orangeTertiary = Color(0xFFFFB876);

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _orangePrimary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE4CC),
      onPrimaryContainer: const Color(0xFF5C2D00),
      secondary: _orangeSecondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFEEE0),
      onSecondaryContainer: const Color(0xFF4A1C00),
      tertiary: _orangeTertiary,
      onTertiary: Colors.white,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF1A1A1A),
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      onSurfaceVariant: const Color(0xFF666666),
      outline: const Color(0xFFCCCCCC),
      error: const Color(0xFFDC3545),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF8F3),
    appBarTheme: AppBarTheme(
      backgroundColor: _orangePrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _orangePrimary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _orangePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _orangePrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orangePrimary, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: const Color(0xFF666666)),
      hintStyle: GoogleFonts.inter(color: const Color(0xFF999999)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _orangePrimary,
      unselectedItemColor: Color(0xFF9E9E9E),
    ),
    dividerColor: const Color(0xFFE0E0E0),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.inter(color: const Color(0xFF1A1A1A)),
      bodyMedium: GoogleFonts.inter(color: const Color(0xFF1A1A1A)),
      bodySmall: GoogleFonts.inter(color: const Color(0xFF666666)),
      titleMedium: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
    ),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _orangePrimary,
      onPrimary: Colors.black87,
      primaryContainer: const Color(0xFF5C2D00),
      onPrimaryContainer: const Color(0xFFFFE4CC),
      secondary: _orangeSecondary,
      onSecondary: Colors.black87,
      secondaryContainer: const Color(0xFF3D1F00),
      onSecondaryContainer: const Color(0xFFFFEEE0),
      tertiary: _orangeTertiary,
      onTertiary: Colors.black87,
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      onSurfaceVariant: const Color(0xFFB0B0B0),
      outline: const Color(0xFF555555),
      error: const Color(0xFFF44336),
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _orangePrimary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _orangePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _orangeSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF444444)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orangePrimary, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0)),
      hintStyle: GoogleFonts.inter(color: const Color(0xFF888888)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: _orangePrimary,
      unselectedItemColor: Color(0xFF757575),
    ),
    dividerColor: const Color(0xFF444444),
    textTheme: TextTheme(
      bodyLarge: GoogleFonts.inter(color: Colors.white),
      bodyMedium: GoogleFonts.inter(color: Colors.white),
      bodySmall: GoogleFonts.inter(color: const Color(0xFFB0B0B0)),
      titleMedium: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}

Future<void> _validatePersistedBackendSession(FFAppState appState) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  // No Firebase session => remove any stale backend user/token from storage.
  if (firebaseUser == null) {
    appState.clearAuthSession();
    return;
  }

  final userId = appState.userid;
  final accessToken = appState.accessToken;
  if (userId == 0 || accessToken.isEmpty) {
    return;
  }

  try {
    final response = await GetUserDetailsCall.call(
      userId: userId,
      token: accessToken,
    );

    if (response.succeeded) {
      final resolvedUserId = GetUserDetailsCall.id(response.jsonBody);
      if (resolvedUserId != null && resolvedUserId != userId) {
        appState.clearAuthSession();
      }
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      appState.clearAuthSession();
    }
  } catch (_) {
    // Keep current session on transient startup errors.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();
  await PaymentConfig().initialize();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();
  await _validatePersistedBackendSession(appState);

  await initializeFirebaseAppCheck();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    setupFirebaseMessaging(_router);
    userStream = ugouserFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ugouser',
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('te'),
        Locale('hi'),
      ],
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}