import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class TomaInventarioScreen extends StatelessWidget {
  const TomaInventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 16,
        left: 8,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => context.go('/inventario'),
          ),
          const SizedBox(width: 8),
          Text(
            'TOMA DE INVENTARIO',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    const buttons = [
      _MenuButton(
        label: 'VER PRODUCTOS',
        route: '/inventario/toma/productos',
        icon: Icons.inventory_2_outlined,
        descripcion: 'Buscar, editar y eliminar productos',
      ),
      _MenuButton(
        label: 'REPORTES',
        route: '/inventario/toma/reportes',
        icon: Icons.picture_as_pdf_outlined,
        descripcion: 'Exportar inventario a PDF',
      ),
    ];

    final isWide = !Breakpoints.isMobile(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isWide
              ? GridView.builder(
                  itemCount: buttons.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 92,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) =>
                      _MenuCard(button: buttons[index]),
                )
              : ListView.separated(
                  itemCount: buttons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _MenuCard(button: buttons[index]),
                ),
        ),
      ),
    );
  }
}

// ─── CARD ──────────────────────────────────────────────────────────────────

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 3),
                    Text(
                      widget.button.descripcion,
                      style: GoogleFonts.inter(
                        color: AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
  final String descripcion;
  const _MenuButton({
    required this.label,
    required this.route,
    required this.icon,
    required this.descripcion,
  });
}