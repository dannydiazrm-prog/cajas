import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

class HojaAjusteScreen extends StatefulWidget {
  const HojaAjusteScreen({super.key});

  @override
  State<HojaAjusteScreen> createState() => _HojaAjusteScreenState();
}

class _HojaAjusteScreenState extends State<HojaAjusteScreen> {
  final _nombreController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _buscado = false;

  Map<String, dynamic>? _productoSeleccionado;

  final _companeroController = TextEditingController();
  final _cantidadController = TextEditingController();
  String? _motivo;
  bool _guardando = false;

  final List<String> _motivos = [
    'Mojado',
    'Roto',
    'Vencido',
    'Perdido',
    'Error de conteo',
    'Otro',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _companeroController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _buscando = true;
      _buscado = false;
      _productoSeleccionado = null;
    });

    List<Map<String, dynamic>> docs = await DataMaster().obtenerProductos();

    final busqueda = _nombreController.text.trim().toLowerCase();
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
      _resultados = docs;
      _buscando = false;
      _buscado = true;
    });
  }

  void _seleccionarProducto(Map<String, dynamic> producto) {
    setState(() {
      _productoSeleccionado = producto;
      _companeroController.clear();
      _cantidadController.clear();
      _motivo = null;
    });
  }

  Future<void> _guardar() async {
    final companero = _companeroController.text.trim();
    final cantidad = int.tryParse(_cantidadController.text.trim());
    final producto = _productoSeleccionado;

    if (producto == null) return;

    if (companero.isEmpty) {
      _mostrarError('Ingresá el nombre del compañero');
      return;
    }
    if (cantidad == null || cantidad <= 0) {
      _mostrarError('Ingresá una cantidad válida');
      return;
    }
    final stockDisponible =
        (producto['stockActual'] as num?)?.toInt() ?? 0;
    if (cantidad > stockDisponible) {
      _mostrarError(
          'La cantidad supera el stock disponible ($stockDisponible)');
      return;
    }
    if (_motivo == null) {
      _mostrarError('Seleccioná un motivo');
      return;
    }

    setState(() => _guardando = true);

    try {
      // Obtener todos los recepcionIds del producto
      final combinaciones = await DataMaster()
          .obtenerCombinacionesRecepcion(producto['id'].toString());

      final recepcionIds = combinaciones
          .expand((c) => List<String>.from(c['recepcionIds'] as List? ?? []))
          .toList();

      await DataMaster().registrarHojaAjuste(
        productoId: producto['id'].toString(),
        companero: companero,
        cantidad: cantidad,
        motivo: _motivo!,
        recepcionIds: recepcionIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hoja de ajuste registrada — $cantidad unidades'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError('Error al guardar. Intentá de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_productoSeleccionado == null) ...[
                      _buildBuscador(),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _buscando ? null : _buscar,
                          icon: const Icon(Icons.search),
                          label: const Text(
                            'BUSCAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_buscando)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      if (_buscado && _resultados.isEmpty)
                        const Center(
                          child: Text(
                            'No se encontraron productos con stock',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ..._resultados.map((doc) => _buildProductoItem(doc)),
                    ] else ...[
                      _buildProductoElegido(),
                      const SizedBox(height: 24),
                      _buildFormulario(),
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

  Widget _buildBuscador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUSCAR PRODUCTO',
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
      ],
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> data) {
    final codigo = data['codigo']?.toString() ?? '';
    final stock = (data['stockActual'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => _seleccionarProducto(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
                      fontSize: 15,
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
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProductoElegido() {
    final p = _productoSeleccionado!;
    final codigo = p['codigo']?.toString() ?? '';

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
                  p['nombre'] ?? '',
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
                    _buildTag(
                        'Stock: ${(p['stockActual'] as num?)?.toInt() ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _productoSeleccionado = null;
            }),
            child: const Text(
              'Cambiar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMPAÑERO',
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
          controller: _companeroController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Nombre del compañero'),
        ),
        const SizedBox(height: 16),
        const Text(
          'CANTIDAD',
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
          decoration: _inputDecoration('Ej: 500'),
        ),
        const SizedBox(height: 16),
        const Text(
          'MOTIVO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _motivo,
              isExpanded: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              hint: Text(
                'Seleccioná un motivo',
                style: TextStyle(color: Colors.grey[500]),
              ),
              items: _motivos
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _motivo = v),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'GUARDAR AJUSTE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'HOJA DE AJUSTE',
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