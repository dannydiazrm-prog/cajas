import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/retirados/retirados_screen.dart';
import '../../presentation/recibidos/recibidos_screen.dart';
import '../../presentation/ajustes/ajustes_screen.dart';
import '../../presentation/inventario/inventario_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/retirados',
      builder: (context, state) => const RetiradosScreen(),
    ),
    GoRoute(
      path: '/recibidos',
      builder: (context, state) => const RecibidosScreen(),
    ),
    GoRoute(
      path: '/ajustes',
      builder: (context, state) => const AjustesScreen(),
    ),
    GoRoute(
      path: '/inventario',
      builder: (context, state) => const InventarioScreen(),
    ),
  ],
);