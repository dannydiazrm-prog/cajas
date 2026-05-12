import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/data_master.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class PendientesScreen extends StatefulWidget {
  const PendientesScreen({super.key});

  @override
  State<PendientesScreen> createState() => _PendientesScreenState();
}

class _PendientesScreenState extends State<PendientesScreen> {
  bool _cerrando = false;
  List<Map<String, dynamic>> _pendientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    setState(() => _cargando = true);
    final retiros = await DataMaster().obtenerRetiros(estado: 'pendiente');
    // Filtrar los que realmente tienen cantidad pendiente y ordenar por fecha
    final filtrados = retiros.where(_tienePendiente).toList();
    filtrados.sort((a, b) {
      final fechaA = DateTime.tryParse(a['fecha'] as String? ?? '') ?? DateTime(2000);
      final fechaB = DateTime.tryParse(b['fecha'] as String? ?? '') ?? DateTime(2000);
      return fechaB.compareTo(fechaA);
    });
    if (mounted) {
      setState(() {
        _pendientes = filtrados;
        _cargando = false;
      });
    }
  }

  bool _tienePendiente(Map<String, dynamic> data) {
    final entregada = (data['cantidadEntregada'] ?? 0) as num;
    final estimada = (data['cantidadEstimada'] ?? 0) as num;
    return entregada > estimada;
  }

  int _cantidadPendiente(Map<String, dynamic> data) {
    final entregada = (data['cantidadEntregada'] ?? 0) as num;
    final estimada = (data['cantidadEstimada'] ?? 0) as num;
    return (entregada - estimada).toInt();
  }

  Future<void> _cerrarConDevolucion(Map<String, dynamic> data) async {
    final pendiente = _cantidadPendiente(data);
    final cantidadCtrl = TextEditingController();
    String error = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(
            'CERRAR CON DEVOLUCIÓN',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pendiente de devolución: $pendiente unidades',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cantidad devuelta',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: $pendiente',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final cantidad = int.tryParse(cantidadCtrl.text.trim());
                if (cantidad == null || cantidad <= 0) {
                  setStateDialog(() => error = 'Ingresa una cantidad válida');
                  return;
                }
                if (cantidad > pendiente) {
                  setStateDialog(
                      () => error = 'No puede ser mayor al pendiente ($pendiente)');
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _cerrando = true);

                try {
                  await DataMaster().cerrarRetiro(
                    retiroId: data['id'] as String,
                    productoId: data['productoId'] as String,
                    destinoId: data['destinoId'] as String? ?? 'todos',
                    cantidadDevuelta: cantidad,
                    motivoCierre: cantidad < pendiente
                        ? 'Devolución parcial'
                        : 'Devolución total',
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vale cerrado correctamente'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al cerrar el vale: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                if (mounted) {
                  setState(() => _cerrando = false);
                  await _cargarPendientes();
                }
              },
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarSinDevolucion(Map<String, dynamic> data) async {
    final motivos = [
      'Pérdida normal del proceso',
      'Quedó en producción',
      'Otro',
    ];
    String? motivoSeleccionado;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(
            'CERRAR SIN DEVOLUCIÓN',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona el motivo:',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...motivos.map((motivo) => GestureDetector(
                    onTap: () =>
                        setStateDialog(() => motivoSeleccionado = motivo),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: motivoSeleccionado == motivo
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        motivo,
                        style: TextStyle(
                          color: motivoSeleccionado == motivo
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: motivoSeleccionado == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      setState(() => _cerrando = true);

                      try {
                        await DataMaster().cerrarRetiro(
                          retiroId: data['id'] as String,
                          productoId: data['productoId'] as String,
                          destinoId: data['destinoId'] as String? ?? 'todos',
                          cantidadDevuelta: 0,
                          motivoCierre: motivoSeleccionado!,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vale cerrado correctamente'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al cerrar el vale: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      if (mounted) {
                        setState(() => _cerrando = false);
                        await _cargarPendientes();
                      }
                    },
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _cerrando || _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _pendientes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primary,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sin pendientes',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No hay devoluciones pendientes',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendientes.length,
                        itemBuilder: (context, index) {
                          final data = _pendientes[index];
                          final pendiente = _cantidadPendiente(data);
                          final fecha = DateTime.tryParse(
                              data['fecha'] as String? ?? '');
                          final fechaStr = fecha != null
                              ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                              : '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.pending_actions,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        data['productoNombre'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border:
                                            Border.all(color: Colors.orange),
                                      ),
                                      child: Text(
                                        '$pendiente pendientes',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildTag('👤 ${data['companero'] ?? ''}'),
                                    _buildTag('📦 Lote: ${data['lote'] ?? ''}'),
                                    _buildTag('🌍 ${data['destino'] ?? ''}'),
                                    _buildTag(
                                        '📤 Entregadas: ${data['cantidadEntregada'] ?? 0}'),
                                    _buildTag(
                                        '🎯 Estimadas: ${data['cantidadEstimada'] ?? 0}'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fechaStr,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _cerrarSinDevolucion(data),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'SIN DEVOLUCIÓN',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _cerrarConDevolucion(data),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'CON DEVOLUCIÓN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/retirados'),
          ),
          const SizedBox(width: 8),
          Text(
            'PENDIENTES DE DEVOLUCIÓN',
            style: TextStyle(
              color: Colors.white,
              fontSize: Breakpoints.isMobile(context) ? 16 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
