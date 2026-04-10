import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
import 'core/providers/locale_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/shared/widgets/app_shell.dart';
import 'features/shared/widgets/stylish_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Show splash for at least 2 seconds so user sees the new loader
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, auth, _) {
        // Show stylish loader during auth init OR until splash min duration reached
        if (auth.isLoading || !_splashDone) {
          return const AppLoadingScreen(message: 'Connecting to BusWay Pro...');
        }
        if (auth.isAuthenticated) {
          return const AppShell();
        }
        return const LoginScreen();
      },
    );
  }
}
