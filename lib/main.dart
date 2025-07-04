import 'package:firebase_core/firebase_core.dart';
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

  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
