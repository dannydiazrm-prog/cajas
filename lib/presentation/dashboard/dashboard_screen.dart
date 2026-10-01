import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _QuickStats(),
              SizedBox(height: 24),
              _MenuGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TARJETAS DE ACCESO RÁPIDO (3 arriba) ──────────────────────────────────

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  Future<Map<String, int>> _cargar() async {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, now.day);
    final fin = inicio.add(const Duration(days: 1));

    final productos = await DataMaster().obtenerProductos();
    final retiros = await DataMaster().obtenerRetiros(desde: inicio, hasta: fin);
    final recepciones =
        await DataMaster().obtenerRecepciones(desde: inicio, hasta: fin);

    final totalRetirados = retiros.fold<int>(
      0,
      (s, r) => s + ((r['cantidadEntregada'] as num?)?.toInt() ?? 0),
    );
    final totalRecibidos = recepciones.fold<int>(
      0,
      (s, r) => s + ((r['cantidad'] as num?)?.toInt() ?? 0),
    );

    return {
      'productos': productos.length,
      'retirados': totalRetirados,
      'recibidos': totalRecibidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _cargar(),
      builder: (context, snap) {
        final data =
            snap.data ?? {'productos': 0, 'retirados': 0, 'recibidos': 0};

        return Row(
          children: [
            Expanded(
              child: _QuickCard(
                label: 'PRODUCTOS',
                valor: data['productos']!,
                icon: Icons.inventory_2_rounded,
                color: AppColors.primary,
                route: '/inventario/toma/productos',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                label: 'RETIRADOS HOY',
                valor: data['retirados']!,
                icon: Icons.output_rounded,
                color: const Color(0xFFD97706),
                route: '/retirados/historial',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                label: 'RECIBIDOS HOY',
                valor: data['recibidos']!,
                icon: Icons.input_rounded,
                color: const Color(0xFF0284C7),
                route: '/recibidos/historial',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickCard extends StatefulWidget {
  final String label;
  final int valor;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;

  String _formatear(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.go(widget.route);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                Color.lerp(widget.color, Colors.black, 0.18)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon,
                        color: Colors.white, size: isMobile ? 16 : 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Text(
                _formatear(widget.valor),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isMobile ? 9 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MENÚS (4 abajo) ───────────────────────────────────────────────────────

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _buttons.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _MenuCard(button: _buttons[index]),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.button.icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.button.label,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textDim,
                size: 20,
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
          GestureDetector(
            onTap: () => _mostrarCreditos(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Icon(
                Icons.code_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
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

  void _mostrarCreditos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.code_rounded, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              'Diseñado por',
              style: GoogleFonts.inter(
                color: AppColors.textDim,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Julio Prieto',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}