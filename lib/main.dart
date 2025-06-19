import 'package:flutter/material.dart';
import 'package:prova/features/auth/signup_screen.dart';
import 'package:prova/features/events/event_list_screen.dart';
import 'package:prova/features/events/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/repositories/auth_repository.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/controllers/auth_controller.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/profile_screen.dart';
import 'core/controllers/event_controller.dart';
import 'core/repositories/event_repository.dart';
import 'core/services/firestore_service.dart';
import 'features/auth/manageevent_screen.dart';
import 'core/providers/user_model_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthRepository>(create: (_) => FirebaseAuthService()),
          ChangeNotifierProvider<AuthController>(
            create: (context) => AuthController(context.read<AuthRepository>()),
          ),
          Provider<EventRepository>(create: (_) => FirestoreService()),
          ChangeNotifierProvider<EventController>(
            create: (context) => EventController(context.read<EventRepository>()),
          ),
          ChangeNotifierProvider<UserModelProvider>(
            create: (_) => UserModelProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Falha ao inicializar o Firebase')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prova Alex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/eventlist': (context) => EventListScreen(),
        '/user-home': (context) => const WelcomeScreen(),
        '/org-home': (context) => const WelcomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/manageevents': (context) => const ManageEventsScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Página não encontrada')),
        ),
      ),
    );
  }
}
