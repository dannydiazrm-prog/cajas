import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RetirosDiаScreen extends StatelessWidget {
  const RetirosDiаScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('RETIROS DEL DÍA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/retirados'),
        ),
      ),
      body: const Center(child: Text('Próximamente...')),
    );
  }
}