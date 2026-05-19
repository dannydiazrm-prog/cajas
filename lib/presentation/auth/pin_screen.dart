import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: const Color(0xFF0a1f17), // verde muy oscuro, neutro
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Header(),
                  const SizedBox(height: 48),
                  _PinIndicator(
                    pinLength: _pin.length,
                    shakeAnimation: _shakeAnimation,
                    error: _error,
                  ),
                  const SizedBox(height: 40),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo con fondo redondeado sutil
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/logo_galmedic.webp',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'GALMEDIC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'DEPÓSITO DE ETIQUETAS',
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
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
          'Ingresá tu PIN',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < pinLength;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: filled ? 18 : 14,
                height: filled ? 18 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: error.isNotEmpty
              ? Text(
                  error,
                  key: ValueKey(error),
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                )
              : const SizedBox(height: 18),
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
      height: 320, // misma altura aprox que el teclado
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verificando...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                letterSpacing: 0.5,
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
    // Responsive: en pantallas anchas (desktop) los botones son un poco más grandes
    final isWide = MediaQuery.of(context).size.width > 600;
    final btnSize = isWide ? 80.0 : 72.0;
    final fontSize = isWide ? 22.0 : 20.0;

    final teclas = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: teclas.map((fila) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fila.map((tecla) {
              if (tecla.isEmpty) {
                return SizedBox(width: btnSize + 16, height: btnSize);
              }

              final isDel = tecla == 'DEL';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _pressed
              ? (widget.isDel
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.9))
              : (widget.isDel
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08)),
          border: Border.all(
            color: widget.isDel
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: widget.isDel
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: widget.fontSize + 2,
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
