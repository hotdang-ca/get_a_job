import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_a_job/data/repositories/auth_repository.dart';
import 'package:get_a_job/logic/blocs/auth_bloc.dart';
import 'package:get_a_job/logic/blocs/auth_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/repositories/job_repository.dart';
import 'logic/blocs/job_bloc.dart';
import 'logic/blocs/job_event.dart';
import 'logic/blocs/theme_bloc.dart';
import 'logic/blocs/theme_state.dart';
import 'presentation/widgets/auth_wrapper.dart';
import 'core/constants.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const GetAJobApp());
}

class GetAJobApp extends StatelessWidget {
  const GetAJobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<JobRepository>(
          create: (context) => SupabaseJobRepository(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => SupabaseAuthRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<JobBloc>(
            create: (context) => JobBloc(
              jobRepository: context.read<JobRepository>(),
            )..add(LoadJobs()),
          ),
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc(),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthInitialized()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Get A Job',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode:
                  themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}
