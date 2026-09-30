import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/data_master.dart';
import '../../core/theme/app_theme.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _error = '';
  bool _loading = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_pin.length < 4 && !_loading) {
      setState(() {
        _pin += digit;
        _error = '';
      });
      if (_pin.length == 4) _validarPin();
    }
  }

  void _borrar() {
    if (_pin.isNotEmpty && !_loading) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _validarPin() async {
    setState(() => _loading = true);
    try {
      final pinCorrecto = await DataMaster().obtenerPin();
      if (_pin == pinCorrecto) {
        if (mounted) context.go('/');
      } else {
        await _shakeController.forward(from: 0);
        setState(() {
          _error = 'PIN incorrecto';
          _pin = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al validar el PIN';
        _pin = '';
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo plano exactamente del mismo verde que el logo.
      // Sin gradiente → el logo se camufla perfecto.
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Header(),
                  const SizedBox(height: 24),
                  _PinIndicator(
                    pinLength: _pin.length,
                    shakeAnimation: _shakeAnimation,
                    error: _error,
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const _LoadingIndicator()
                  else
                    _Teclado(onKey: _onKey, onBorrar: _borrar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HEADER ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Image.asset(
            'assets/images/logo_galmedic.webp',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'GALMEDIC',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'DEPÓSITO DE CAJAS',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ─── PIN INDICATOR ─────────────────────────────────────────────────────────

class _PinIndicator extends StatelessWidget {
  final int pinLength;
  final Animation<double> shakeAnimation;
  final String error;

  const _PinIndicator({
    required this.pinLength,
    required this.shakeAnimation,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'INGRESA TU PIN',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: shakeAnimation,
          builder: (context, child) {
            final offset =
                (shakeAnimation.value * 12 * (1 - shakeAnimation.value))
                    .clamp(-8.0, 8.0);
            return Transform.translate(
              offset: Offset(offset * 4, 0),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final filled = i < pinLength;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  margin: EdgeInsets.symmetric(horizontal: i == 3 ? 0 : 12),
                  width: filled ? 18 : 14,
                  height: filled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.30),
                      width: 1.6,
                    ),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: error.isNotEmpty
              ? Container(
                  key: ValueKey(error),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        error,
                        style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(height: 28),
        ),
      ],
    );
  }
}

// ─── LOADING ───────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'VERIFICANDO',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TECLADO ───────────────────────────────────────────────────────────────

class _Teclado extends StatelessWidget {
  final Function(String) onKey;
  final VoidCallback onBorrar;

  const _Teclado({required this.onKey, required this.onBorrar});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final btnSize = isWide ? 64.0 : 58.0;
    final fontSize = isWide ? 20.0 : 19.0;
    final gap = isWide ? 12.0 : 10.0;

    final teclas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: teclas.map((fila) {
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fila.map((tecla) {
              if (tecla.isEmpty) {
                return SizedBox(width: btnSize + gap, height: btnSize);
              }
              final isDel = tecla == 'DEL';
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: _TeclaButton(
                  label: tecla,
                  isDel: isDel,
                  size: btnSize,
                  fontSize: fontSize,
                  onTap: isDel ? onBorrar : () => onKey(tecla),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _TeclaButton extends StatefulWidget {
  final String label;
  final bool isDel;
  final double size;
  final double fontSize;
  final VoidCallback onTap;

  const _TeclaButton({
    required this.label,
    required this.isDel,
    required this.size,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<_TeclaButton> createState() => _TeclaButtonState();
}

class _TeclaButtonState extends State<_TeclaButton> {
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
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed
                ? (widget.isDel
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.95))
                : (widget.isDel
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.12)),
            border: Border.all(
              color: Colors.white.withValues(
                  alpha: widget.isDel ? 0.10 : 0.16),
              width: 1,
            ),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isDel
                ? Icon(
                    Icons.backspace_outlined,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: widget.fontSize + 2,
                  )
                : Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w500,
                      color: _pressed ? AppColors.primary : Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}