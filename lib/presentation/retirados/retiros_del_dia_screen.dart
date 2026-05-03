import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RetirosDiaScreen extends StatelessWidget {
  const RetirosDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('RETIROS DEL DIA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/retirados'),
        ),
      ),
      body: const Center(child: Text('Proximamente...')),
    );
  }
}