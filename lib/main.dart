import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/router.dart';

void main() {
  runApp(const ProviderScope(child: OrionsEyeApp()));
}

class OrionsEyeApp extends ConsumerWidget {
  const OrionsEyeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: "Orion's Eye",
      debugShowCheckedModeBanner: false,
      theme: AppTheme. darkTheme,
      routerConfig: router,
    );
  }
}