import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

class NuevoDestinoScreen extends StatefulWidget {
  const NuevoDestinoScreen({super.key});

  @override
  State<NuevoDestinoScreen> createState() => _NuevoDestinoScreenState();
}

class _NuevoDestinoScreenState extends State<NuevoDestinoScreen> {
  final _nombreController = TextEditingController();
  bool _loading = false;
  String _error = '';
  String _busqueda = '';
  final _busquedaController = TextEditingController();
  List<Map<String, dynamic>> _destinos = [];

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDestinos() async {
    final lista = await DataMaster().obtenerDestinos();
    if (mounted) {
      setState(() => _destinos = lista);
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa el nombre del destino');
      return;
    }

    // Verificar que no exista ya un destino con el mismo nombre
    final yaExiste = _destinos.any(
      (d) => (d['nombre'] ?? '').toString().toLowerCase() ==
          nombre.toLowerCase(),
    );
    if (yaExiste) {
      setState(() => _error = 'Ya existe un destino con ese nombre');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await DataMaster().crearDestino(nombre: nombre);

      if (mounted) {
        _nombreController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destino creado correctamente'),
            backgroundColor: AppColors.primary,
          ),
        );
        await _cargarDestinos();
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar. Intentá de nuevo.');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _eliminar(String id, bool editable) async {
    if (!editable) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar destino'),
        content: const Text(
            '¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Verificar si el destino tiene productos asociados
      final db = await DataMaster().db;
      final recepciones = await db.query(
        'recepciones',
        where: 'destinoId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (recepciones.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se puede eliminar: el destino tiene productos asociados.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await DataMaster().eliminarDestino(id: id);
      await _cargarDestinos();
    }
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
                      const Text(
                        'NUEVO DESTINO',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Color(0xFF0c6246)),
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Ej: Fondilac, Local, Riegos Modernos',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            _error,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _guardar,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'GUARDAR DESTINO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Text(
                            'DESTINOS EXISTENTES',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_destinos.length})',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style: const TextStyle(color: Color(0xFF0c6246)),
                        controller: _busquedaController,
                        onChanged: (v) => setState(() => _busqueda = v),
                        decoration: InputDecoration(
                          hintText: 'Buscar destino...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_destinos.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay destinos creados todavía',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ...(_destinos.where((d) {
                        if (_busqueda.isEmpty) return true;
                        return (d['nombre'] ?? '').toString().toLowerCase().contains(_busqueda.toLowerCase());
                      }).map((d) {
                        final editable = (d['editable'] == 1 || d['editable'] == true);
                        return _buildDestinoItem(
                          nombre: d['nombre']?.toString() ?? '',
                          editable: editable,
                          onEliminar: editable ? () => _eliminar(d['id']?.toString() ?? '', editable) : null,
                        );
                      })),
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

  Widget _buildDestinoItem({
    required String nombre,
    required bool editable,
    VoidCallback? onEliminar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: editable && onEliminar != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: onEliminar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : const Icon(Icons.lock_outline, color: AppColors.onSurfaceDim, size: 16),
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
            onPressed: () => context.go('/inventario'),
          ),
          const SizedBox(width: 8),
          Text(
            'DESTINOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: Breakpoints.isMobile(context) ? 20 : 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
