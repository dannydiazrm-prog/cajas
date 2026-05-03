import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RetiradosScreen extends StatelessWidget {    
  const RetiradosScreen({super.key});              
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('RETIRADOS'),            
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(
        child: Text('Próximamente...'),
      ),
    );
  }
}