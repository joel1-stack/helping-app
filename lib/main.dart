import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:helping_hands/screens/HomeScreen.dart';
import 'package:helping_hands/screens/LoginScreen.dart';
import 'package:helping_hands/screens/SignUpScreen.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/help_request_service.dart';
import 'services/chat_service.dart';
import 'services/profile_service.dart';
import 'services/ratings_service.dart'; // Add this import
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HelpingHandsApp());
}

class HelpingHandsApp extends StatelessWidget {
  const HelpingHandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<HelpRequestService>(create: (_) => HelpRequestService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<RatingsService>(create: (_) => RatingsService()), // Add RatingsService
        StreamProvider<UserModel?>(
          create: (context) => context.read<AuthService>().currentUser,
          initialData: null,
          catchError: (_, error) {
            print('Error in user stream: $error');
            return null;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Helping Hands',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins',
        ),
        home: const AppEntryPoint(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) {
            final user = Provider.of<UserModel?>(context);
            return user != null ? HomeScreen(user: user) : const LoginScreen();
          },
        },
      ),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _showAnimatedSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showAnimatedSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show animated splash screen first
    if (_showAnimatedSplash) {
      return SplashScreen(
        onAnimationComplete: _onSplashComplete,
        splashDuration: const Duration(minutes: 30), // 30 MINUTES SPLASH
      );
    }

    // After splash, show auth wrapper
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    print('AuthWrapper - User state: ${user?.email ?? "Not logged in"}');

    if (user == null) {
      return StreamBuilder<UserModel?>(
        stream: Provider.of<AuthService>(context, listen: false).currentUser,
        builder: (context, snapshot) {
          // Show loading screen while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          // If user exists, go to home screen
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }

          // No user, go to login
          return const LoginScreen();
        },
      );
    }

    // User is logged in, go to home screen
    return HomeScreen(user: user);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade500,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Helping Hands',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}