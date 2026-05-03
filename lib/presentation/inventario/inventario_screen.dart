import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class InventarioScreen extends StatelessWidget {    
  const InventarioScreen({super.key});              
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('INVENTARIO'),            
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