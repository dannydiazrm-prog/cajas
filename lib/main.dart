import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'core/data/data_master.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    final maestro = DataMaster();
    await maestro.init();
    await maestro.inicializar();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  runApp(
    const ProviderScope(child: GalmedicApp()),
  );
}

class GalmedicApp extends StatelessWidget {
  const GalmedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Depósito de Etiquetas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
      builder: (context, child) {
        precacheImage(
          const AssetImage('assets/images/fondo_animales.webp'),
          context,
        );
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: AppColors.surface,
            ),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyLarge!.copyWith(
              color: AppColors.onBackground,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: AppColors.background),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      'assets/images/fondo_animales.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                child!,
              ],
            ),
          ),
        );
      },
    );
  }
}