import 'package:admindoorstep/app_constants.dart';
import 'package:admindoorstep/app_routes.dart';
import 'package:admindoorstep/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supaBaseUrl,
    anonKey: AppConstants.supaBaseAnonKey,
  );

  runApp(const AdminDoorstepApp());
}

class AdminDoorstepApp extends StatelessWidget {
  const AdminDoorstepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'admindoorstep',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
          scaffoldBackgroundColor: const Color(0xFFF3F7F6),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}
