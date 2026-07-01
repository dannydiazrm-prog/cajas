import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

class TransferirStockScreen extends StatefulWidget {
  const TransferirStockScreen({super.key});

  @override
  State<TransferirStockScreen> createState() => _TransferirStockScreenState();
}

class _TransferirStockScreenState extends State<TransferirStockScreen> {
  // Búsqueda origen
  final _busquedaOrigenController = TextEditingController();
  Map<String, dynamic>? _productoOrigen;
  List<Map<String, dynamic>> _resultadosOrigen = [];
  bool _buscandoOrigen = false;
  bool _buscadoOrigen = false;

  // Búsqueda destino
  final _busquedaDestinoController = TextEditingController();
  Map<String, dynamic>? _productoDestino;
  List<Map<String, dynamic>> _resultadosDestino = [];
  bool _buscandoDestino = false;
  bool _buscadoDestino = false;

  // Cantidad
  final _cantidadController = TextEditingController();
  bool _guardando = false;
  String _error = '';

  @override
  void dispose() {
    _busquedaOrigenController.dispose();
    _busquedaDestinoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _buscarOrigen() async {
    setState(() {
      _buscandoOrigen = true;
      _buscadoOrigen = false;
      _productoOrigen = null;
    });

    List<Map<String, dynamic>> docs = await DataMaster().obtenerProductos();

    final busqueda = _busquedaOrigenController.text.trim().toLowerCase();
    if (busqueda.isNotEmpty) {
      docs = docs.where((d) {
        final matchNombre =
            (d['nombre'] ?? '').toString().toLowerCase().contains(busqueda);
        final matchCodigo =
            (d['codigo'] ?? '').toString().toLowerCase().contains(busqueda);
        return matchNombre || matchCodigo;
      }).toList();
    }

    docs = docs
        .where((d) => ((d['stockActual'] as num?)?.toInt() ?? 0) > 0)
        .toList();

    setState(() {
      _resultadosOrigen = docs;
      _buscandoOrigen = false;
      _buscadoOrigen = true;
    });
  }

  Future<void> _buscarDestino() async {
    setState(() {
      _buscandoDestino = true;
      _buscadoDestino = false;
      _productoDestino = null;
    });

    List<Map<String, dynamic>> docs = await DataMaster().obtenerProductos();

    final busqueda = _busquedaDestinoController.text.trim().toLowerCase();
    if (busqueda.isNotEmpty) {
      docs = docs.where((d) {
        final matchNombre =
            (d['nombre'] ?? '').toString().toLowerCase().contains(busqueda);
        final matchCodigo =
            (d['codigo'] ?? '').toString().toLowerCase().contains(busqueda);
        return matchNombre || matchCodigo;
      }).toList();
    }

    // Excluir el producto origen
    if (_productoOrigen != null) {
      docs = docs
          .where((d) => d['id'] != _productoOrigen!['id'])
          .toList();
    }

    setState(() {
      _resultadosDestino = docs;
      _buscandoDestino = false;
      _buscadoDestino = true;
    });
  }

  Future<void> _confirmar() async {
    final cantidad = int.tryParse(_cantidadController.text.trim());

    if (_productoOrigen == null) {
      setState(() => _error = 'Seleccioná el producto origen');
      return;
    }
    if (_productoDestino == null) {
      setState(() => _error = 'Seleccioná el producto destino');
      return;
    }
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'Ingresá una cantidad válida');
      return;
    }

    final stockDisponible =
        (_productoOrigen!['stockActual'] as num?)?.toInt() ?? 0;
    if (cantidad > stockDisponible) {
      setState(() =>
          _error = 'Stock insuficiente en origen. Disponible: $stockDisponible');
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      // 1 — Restar del origen
      final combinacionesOrigen = await DataMaster()
          .obtenerCombinacionesRecepcion(_productoOrigen!['id'].toString());

      final recepcionIdsOrigen = combinacionesOrigen
          .expand(
              (c) => List<String>.from(c['recepcionIds'] as List? ?? []))
          .toList();

      await DataMaster().registrarAjuste(
        tipo: 'ajuste_manual',
        tipoAjuste: 'resta',
        productoId: _productoOrigen!['id'].toString(),
        productoNombre: _productoOrigen!['nombre'].toString(),
        tipoProducto: _productoOrigen!['tipo']?.toString() ?? '',
        idioma: _productoOrigen!['idioma']?.toString() ?? '',
        cantidad: cantidad,
        motivo:
            'Transferencia a código ${_productoDestino!['codigo'] ?? _productoDestino!['nombre']}',
        destinosIds: ['general'],
        recepcionIds: recepcionIdsOrigen,
      );

      // 2 — Sumar al destino
      await DataMaster().registrarRecepcion(
        productoId: _productoDestino!['id'].toString(),
        productoNombre: _productoDestino!['nombre'] ?? '',
        tipo: _productoDestino!['tipo'] ?? '',
        idioma: _productoDestino!['idioma'] ?? '',
        cantidad: cantidad,
        codigo: _productoDestino!['codigo']?.toString() ?? '',
        destinoClave: 'general',
        destinos: ['general'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$cantidad unidades transferidas a ${_productoDestino!['nombre']}'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/inventario');
      }
    } catch (e) {
      setState(() => _error = 'Error al transferir: $e');
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ORIGEN
                    _buildSeccion(
                      titulo: 'PRODUCTO ORIGEN',
                      subtitulo: 'El stock se va a descontar de acá',
                      producto: _productoOrigen,
                      busquedaController: _busquedaOrigenController,
                      resultados: _resultadosOrigen,
                      buscando: _buscandoOrigen,
                      buscado: _buscadoOrigen,
                      onBuscar: _buscarOrigen,
                      onSeleccionar: (data) => setState(() {
                        _productoOrigen = data;
                        _resultadosOrigen = [];
                        _buscadoOrigen = false;
                        _busquedaOrigenController.clear();
                        _error = '';
                      }),
                      onCambiar: () => setState(() {
                        _productoOrigen = null;
                        _error = '';
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Flecha visual
                    if (_productoOrigen != null)
                      const Center(
                        child: Icon(
                          Icons.arrow_downward,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),

                    if (_productoOrigen != null) const SizedBox(height: 24),

                    // DESTINO
                    if (_productoOrigen != null)
                      _buildSeccion(
                        titulo: 'PRODUCTO DESTINO',
                        subtitulo: 'El stock se va a sumar acá',
                        producto: _productoDestino,
                        busquedaController: _busquedaDestinoController,
                        resultados: _resultadosDestino,
                        buscando: _buscandoDestino,
                        buscado: _buscadoDestino,
                        onBuscar: _buscarDestino,
                        onSeleccionar: (data) => setState(() {
                          _productoDestino = data;
                          _resultadosDestino = [];
                          _buscadoDestino = false;
                          _busquedaDestinoController.clear();
                          _error = '';
                        }),
                        onCambiar: () => setState(() {
                          _productoDestino = null;
                          _error = '';
                        }),
                      ),

                    if (_productoOrigen != null && _productoDestino != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'CANTIDAD A TRANSFERIR',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        style: const TextStyle(color: Color(0xFF0c6246)),
                        controller: _cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ej: 1000',
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
                      const SizedBox(height: 32),
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
                          onPressed: _guardando ? null : _confirmar,
                          child: _guardando
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'CONFIRMAR TRANSFERENCIA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required String subtitulo,
    required Map<String, dynamic>? producto,
    required TextEditingController busquedaController,
    required List<Map<String, dynamic>> resultados,
    required bool buscando,
    required bool buscado,
    required VoidCallback onBuscar,
    required Function(Map<String, dynamic>) onSeleccionar,
    required VoidCallback onCambiar,
  }) {
    if (producto != null) {
      final codigo = producto['codigo']?.toString() ?? '';
      final stock = (producto['stockActual'] as num?)?.toInt() ?? 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto['nombre'] ?? '',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (codigo.isNotEmpty) _buildTag('Cód: $codigo'),
                      _buildTag('Stock: $stock'),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onCambiar,
              child: const Text('Cambiar',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: const TextStyle(color: AppColors.primary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        TextField(
          style: const TextStyle(color: Color(0xFF0c6246)),
          controller: busquedaController,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o código',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: buscando ? null : onBuscar,
            icon: const Icon(Icons.search),
            label: Text(
              buscando ? 'BUSCANDO...' : 'BUSCAR',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (buscado && resultados.isEmpty)
          const Center(
            child: Text(
              'No se encontraron productos',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ...resultados.map((data) {
          final codigo = data['codigo']?.toString() ?? '';
          final stock = (data['stockActual'] as num?)?.toInt() ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSeleccionar(data),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nombre'] ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (codigo.isNotEmpty)
                                _buildTag('Cód: $codigo'),
                              _buildTag('Stock: $stock'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
            onPressed: () => context.go('/inventario'),
          ),
          const SizedBox(width: 8),
          Text(
            'TRANSFERIR STOCK',
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