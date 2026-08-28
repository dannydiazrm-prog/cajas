import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(),
          Expanded(
            child: _Body(),
          ),
          _Footer(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_galmedic.webp',
            height: 80,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'DEPÓSITO DE CAJAS.',
              style: TextStyle(
                color: Colors.white,
                fontSize: Breakpoints.isMobile(context) ? 16 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () => context.push('/perfil'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.manage_accounts_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<_MenuButton> buttons = const [
    _MenuButton(label: 'RETIRADOS', route: '/retirados', icon: Icons.output),
    _MenuButton(label: 'RECIBIDOS', route: '/recibidos', icon: Icons.input),
    _MenuButton(label: 'HOJA DE AJUSTES', route: '/ajustes', icon: Icons.tune),
    _MenuButton(label: 'INVENTARIO', route: '/inventario', icon: Icons.inventory_2),
  ];

  @override
  Widget build(BuildContext context) {
    // Grid con card de tamaño FIJO (no proporcional al ancho de pantalla).
    // Esto evita que las cards se agranden en landscape mobile o en
    // ventanas anchas de Windows: en vez de estirarse, el grid simplemente
    // agrega más columnas si hay espacio disponible.
    return Center(
      child: ConstrainedBox(
        // Tope de ancho total para que en Windows no quede una grilla
        // gigante pegada a los bordes, sino un panel centrado y prolijo.
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            itemCount: buttons.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 84,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemBuilder: (context, index) =>
                _buildButton(context, buttons[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, _MenuButton button) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: () => context.go(button.route),
        child: Text(
          button.label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _MenuButton {
  final String label;
  final String route;
  final IconData icon;
  const _MenuButton({
    required this.label,
    required this.route,
    required this.icon,
  });
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        bottom: bottomPadding + 12,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '09/2026',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'VERSIÓN 1.0',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
