import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          Expanded(child: _Body()),
          _Footer(),
        ],
      ),
    );
  }
}

// ─── HEADER ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isMobile = Breakpoints.isMobile(context);

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
              'DEPÓSITO DE CAJAS',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: isMobile ? 16 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          _ProfileButton(onTap: () => context.push('/perfil')),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ProfileButton({required this.onTap});

  @override
  State<_ProfileButton> createState() => _ProfileButtonState();
}

class _ProfileButtonState extends State<_ProfileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _pressed ? 0.24 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.settings_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ─── BODY ──────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  static const List<_MenuButton> _buttons = [
    _MenuButton(
      label: 'RETIRADOS',
      route: '/retirados',
      icon: Icons.output_rounded,
    ),
    _MenuButton(
      label: 'RECIBIDOS',
      route: '/recibidos',
      icon: Icons.input_rounded,
    ),
    _MenuButton(
      label: 'HOJA DE AJUSTES',
      route: '/ajustes',
      icon: Icons.tune_rounded,
    ),
    _MenuButton(
      label: 'INVENTARIO',
      route: '/inventario',
      icon: Icons.inventory_2_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            itemCount: _buttons.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisExtent: 92,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) =>
                _MenuCard(button: _buttons[index]),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final _MenuButton button;
  const _MenuCard({required this.button});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.go(widget.button.route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.surfaceAlt : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _pressed ? AppColors.primary : AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.02 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.button.icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.button.label,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDim,
                size: 22,
              ),
            ],
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

// ─── FOOTER ────────────────────────────────────────────────────────────────

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
        children: [
          Text(
            '10/2026',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'VERSIÓN 1.0',
            style: GoogleFonts.inter(
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