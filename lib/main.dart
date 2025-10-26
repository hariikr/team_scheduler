import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/auth_service.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/auth/auth_state.dart' as app_auth;
import 'presentation/auth/login_screen.dart';
import 'presentation/availability/availability_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://gjvfbcyulhendnccpkoq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqdmZiY3l1bGhlbmRuY2Nwa29xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MDk3NDcsImV4cCI6MjA3Njk4NTc0N30.xb9y2UtOF7jOyQV5eBTJHi1xSTq3LozIKLEoYFH73uI',
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthCubit(AuthService(Supabase.instance.client))..checkAuthStatus(),
      child: MaterialApp(
        title: 'Team Scheduler',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, app_auth.AuthState>(
      builder: (context, state) {
        if (state is app_auth.AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is app_auth.AuthAuthenticated) {
          return AvailabilityScreen(userId: state.user.id);
        }

        return const LoginScreen();
      },
    );
  }
}
