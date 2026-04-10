import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/fee_provider.dart';
import 'core/providers/student_provider.dart';
import 'core/providers/bus_provider.dart';
import 'core/providers/route_provider.dart';
import 'core/providers/attendance_provider.dart';
import 'core/providers/admin_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow Google Fonts HTTP fetching on all platforms
  GoogleFonts.config.allowRuntimeFetching = true;

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const SchoolBusApp());
}

final supabase = Supabase.instance.client;

class SchoolBusApp extends StatelessWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'BusWay Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.slate900,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo matching loading screen
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24)],
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text('BUSWAY PRO', style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('ENTERPRISE FLEET', style: GoogleFonts.plusJakartaSans(
                    fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const AppShell();
        }

        // Show login with error if there was one
        return const LoginScreen();
      },
    );
  }
}
