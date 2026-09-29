import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/data_master.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _pinActualController = TextEditingController();
  final _pinNuevoController = TextEditingController();
  final _pinConfirmController = TextEditingController();
  String _mensaje = '';
  bool _loading = false;
  bool _ocultarActual = true;
  bool _ocultarNuevo = true;
  bool _ocultarConfirm = true;
  bool _sincronizando = false;
  String _estadoSync = '';
  int _pendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    final total = await DataMaster().contarPendientes();
    if (mounted) setState(() => _pendientes = total);
  }

  @override
  void dispose() {
    _pinActualController.dispose();
    _pinNuevoController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  Future<void> _cambiarPin() async {
    final actual = _pinActualController.text.trim();
    final nuevo = _pinNuevoController.text.trim();
    final confirm = _pinConfirmController.text.trim();

    if (actual.isEmpty || nuevo.isEmpty || confirm.isEmpty) {
      setState(() => _mensaje = 'Completá todos los campos');
      return;
    }
    if (nuevo.length != 4 || int.tryParse(nuevo) == null) {
      setState(() => _mensaje = 'El PIN debe ser de 4 dígitos');
      return;
    }
    if (nuevo != confirm) {
      setState(() => _mensaje = 'Los PINs nuevos no coinciden');
      return;
    }

    setState(() => _loading = true);

    try {
      final pinGuardado = await DataMaster().leerConfig('pin') ?? '1234';

      if (actual != pinGuardado) {
        setState(() => _mensaje = 'PIN actual incorrecto');
      } else {
        await DataMaster().guardarConfig('pin', nuevo);

        try {
          await FirebaseFirestore.instance
              .collection('config')
              .doc('pin')
              .set({'valor': nuevo});
        } catch (_) {}

        setState(() => _mensaje = 'PIN actualizado correctamente');
        _pinActualController.clear();
        _pinNuevoController.clear();
        _pinConfirmController.clear();
      }
    } catch (e) {
      setState(() => _mensaje = 'Error al actualizar el PIN');
    }

    setState(() => _loading = false);
  }

  Future<void> _sincronizar() async {
    setState(() {
      _sincronizando = true;
      _estadoSync = '';
    });

    try {
      await DataMaster().sincronizar();
      final pendientes = await DataMaster().contarPendientes();
      if (mounted) {
        setState(() {
          _pendientes = pendientes;
          _estadoSync = 'Sincronización completada';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _estadoSync = 'Error al sincronizar: $e');
    }

    if (mounted) setState(() => _sincronizando = false);
  }

  void _cerrarSesion() {
    context.go('/pin');
  }

  Future<void> _accederGestionDatos(BuildContext context) async {
    String pin = '';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'GESTIÓN DE DATOS',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu PIN para continuar',
              style: GoogleFonts.inter(
                color: AppColors.textBody,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                letterSpacing: 4,
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '****',
                counterText: '',
              ),
              onChanged: (v) => pin = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: AppColors.textBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ENTRAR'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final pinGuardado = await DataMaster().leerConfig('pin') ?? '';

    if (pin != pinGuardado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorrecto')),
        );
      }
      return;
    }

    if (mounted) context.push('/perfil/gestion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN SINCRONIZACIÓN
                      _SyncCard(
                        pendientes: _pendientes,
                        estadoSync: _estadoSync,
                        sincronizando: _sincronizando,
                        onSync: _sincronizar,
                      ),
                      const SizedBox(height: 32),

                      // SECCIÓN CAMBIAR PIN
                      Text(
                        'CAMBIAR PIN',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCampoPin(
                        controller: _pinActualController,
                        label: 'PIN actual',
                        ocultar: _ocultarActual,
                        onToggle: () =>
                            setState(() => _ocultarActual = !_ocultarActual),
                      ),
                      const SizedBox(height: 16),
                      _buildCampoPin(
                        controller: _pinNuevoController,
                        label: 'PIN nuevo',
                        ocultar: _ocultarNuevo,
                        onToggle: () =>
                            setState(() => _ocultarNuevo = !_ocultarNuevo),
                      ),
                      const SizedBox(height: 16),
                      _buildCampoPin(
                        controller: _pinConfirmController,
                        label: 'Confirmar PIN nuevo',
                        ocultar: _ocultarConfirm,
                        onToggle: () =>
                            setState(() => _ocultarConfirm = !_ocultarConfirm),
                      ),
                      const SizedBox(height: 20),
                      if (_mensaje.isNotEmpty)
                        _MensajeBox(mensaje: _mensaje),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _cambiarPin,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'GUARDAR NUEVO PIN',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Divider(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout, size: 20),
                          label: Text(
                            'CERRAR SESIÓN',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PERFIL',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: isMobile ? 20 : 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
            onPressed: () => _accederGestionDatos(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoPin({
    required TextEditingController controller,
    required String label,
    required bool ocultar,
    required VoidCallback onToggle,
  }) {
    return TextField(
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        letterSpacing: 4,
        fontWeight: FontWeight.w600,
      ),
      controller: controller,
      obscureText: ocultar,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            ocultar ? Icons.visibility_off : Icons.visibility,
            color: AppColors.primary,
          ),
          onPressed: onToggle,
        ),
        counterText: '',
      ),
    );
  }
}

// ─── SYNC CARD ─────────────────────────────────────────────────────────────

class _SyncCard extends StatelessWidget {
  final int pendientes;
  final String estadoSync;
  final bool sincronizando;
  final Future<void> Function() onSync;

  const _SyncCard({
    required this.pendientes,
    required this.estadoSync,
    required this.sincronizando,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final hayPendientes = pendientes > 0;
    final color = hayPendientes ? AppColors.warning : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hayPendientes
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.border,
          width: hayPendientes ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hayPendientes
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  hayPendientes
                      ? '$pendientes registro${pendientes != 1 ? 's' : ''} pendiente${pendientes != 1 ? 's' : ''} de sincronizar'
                      : 'Todo sincronizado con Firebase',
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          if (estadoSync.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (estadoSync.contains('Error')
                        ? AppColors.error
                        : AppColors.success)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                estadoSync,
                style: GoogleFonts.inter(
                  color: estadoSync.contains('Error')
                      ? AppColors.error
                      : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: sincronizando ? null : onSync,
              icon: sincronizando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sync, size: 20),
              label: Text(
                sincronizando
                    ? 'SINCRONIZANDO...'
                    : 'SINCRONIZAR CON FIREBASE',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MENSAJE BOX ───────────────────────────────────────────────────────────

class _MensajeBox extends StatelessWidget {
  final String mensaje;
  const _MensajeBox({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esExito = mensaje.contains('correctamente');
    final color = esExito ? AppColors.success : AppColors.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            esExito ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}