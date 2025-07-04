import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/pages/forget_page.dart';
import 'package:ourchat/pages/login_page.dart';
import 'package:ourchat/pages/register_page.dart';
import 'package:ourchat/pages/splash_page.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/media_service.dart';
import 'package:ourchat/services/navigation_service.dart';
import 'package:ourchat/services/supabase_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';

void setupServices() {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<NavigationService>()) {
    getIt.registerSingleton<NavigationService>(NavigationService());
  }
  if (!getIt.isRegistered<DatabaseService>()) {
    getIt.registerSingleton<DatabaseService>(DatabaseService());
  }
  if (!getIt.isRegistered<MediaService>()) {
    getIt.registerSingleton<MediaService>(MediaService());
  }
  if (!getIt.isRegistered<SupabaseStorageService>()) {
    getIt.registerSingleton<SupabaseStorageService>(SupabaseStorageService());
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  String supabaseUrl = "";
  String supabaseAnonKey = "";

  if (kIsWeb) {
    supabaseUrl = 'https://gadcbmparcoqebtwqfth.supabase.co';
    supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhZGNibXBhcmNvcWVidHdxZnRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxMzc0MTgsImV4cCI6MjA2NTcxMzQxOH0.Xp0s7J_fj6aQz3XZSlqB6L_aP7sZrwapu4KNAvcyDjc';
  } else {
    await dotenv.load();
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  setupServices();

  runApp(const AppEntry());
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProviderFirebase>(
          create: (_) => AuthenticationProviderFirebase(),
        ),
      ],
      child: MaterialApp(
        title: 'OurChat',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromRGBO(36, 35, 49, 1.0),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color.fromRGBO(30, 29, 37, 1.0),
          ),
        ),
        navigatorKey: NavigationService.navigatorKey,
        home: _initialized
            ? LoginPage()
            : SplashPage(
                onInitializationComplete: () {
                  setState(() {
                    _initialized = true;
                  });
                },
              ),
        routes: {
          '/login': (BuildContext _context) => LoginPage(),
          '/register': (BuildContext _context) => RegisterPage(),
          '/home': (BuildContext _context) => HomePage(),
          '/forget': (BuildContext _context) => ForgetPage(),
        },
      ),
    );
  }
}
