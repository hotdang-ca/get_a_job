import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/auth_bloc.dart';
import '../../logic/blocs/auth_state.dart';
import '../screens/landing_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitialState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is Authenticated) {
          return const HomeScreen(isGuestMode: false);
        }

        if (state is GuestMode) {
          return const HomeScreen(isGuestMode: true);
        }

        // Unauthenticated or AccountRequestSubmitted
        return const LandingScreen();
      },
    );
  }
}
