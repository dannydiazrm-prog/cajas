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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: Container(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Padding(
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
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: Breakpoints.isMobile(context) ? 16 : 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _ProfileButton(onTap: () => context.push('/perfil')),
              ],
            ),
          ),
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
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pressed
                ? [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.18),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.settings_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── BODY ──────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<_MenuButton> buttons = const [
    _MenuButton(label: 'RETIRADOS', route: '/retirados', icon: Icons.output),
    _MenuButton(label: 'RECIBIDOS', route: '/recibidos', icon: Icons.input),
    _MenuButton(label: 'HOJA DE AJUSTES', route: '/ajustes', icon: Icons.tune),
    _MenuButton(label: 'INVENTARIO', route: '/inventario', icon: Icons.inventory_2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFEAF3EE),
            Color(0xFFD9E8E0),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
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
                  _MenuCard(button: buttons[index]),
            ),
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          context.go(widget.button.route);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pressed
                    ? const [
                        Color(0xFF0A5039),
                        Color(0xFF094A35),
                        Color(0xFF073A2A),
                      ]
                    : (_hovered
                        ? const [
                            Color(0xFF128162),
                            Color(0xFF0D6E4F),
                            Color(0xFF0A5A42),
                          ]
                        : const [
                            Color(0xFF0F7153),
                            Color(0xFF0C6246),
                            Color(0xFF09543C),
                          ]),
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: _pressed
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: _hovered ? 0.38 : 0.28),
                        blurRadius: _hovered ? 20 : 14,
                        offset: Offset(0, _hovered ? 10 : 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.32),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.button.label,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: Container(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Padding(
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
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                Text(
                  'VERSIÓN 1.0',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}