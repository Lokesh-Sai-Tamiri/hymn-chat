import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase with Twilio Verify
    await SupabaseService.initialize();
    
    if (AppConfig.debugMode) {
      print('🚀 HymnChat initialized successfully');
    }
  } catch (e) {
    if (AppConfig.debugMode) {
      print('❌ Initialization error: $e');
      print('⚠️ Make sure to configure Supabase credentials in app_config.dart');
    }
  }
  
  runApp(const ProviderScope(child: HymnChatApp()));
}

class HymnChatApp extends ConsumerWidget {
  const HymnChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hymn Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
