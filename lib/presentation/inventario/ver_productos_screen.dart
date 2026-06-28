import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

class VerProductosScreen extends StatefulWidget {
  const VerProductosScreen({super.key});

  @override
  State<VerProductosScreen> createState() => _VerProductosScreenState();
}

class _VerProductosScreenState extends State<VerProductosScreen> {
  final _nombreController = TextEditingController();
  bool _conStock = false;
  bool _sinStock = false;
  Set<String> _prefijosSeleccionados = {};
  List<String> _prefijosUsados = [];
  bool _cargandoPrefijos = true;
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _buscado = false;
  Map<String, Map<String, int>> _stockPorCodigo = {};
  List<String> _prefijosActivos = [];

  @override
  void initState() {
    super.initState();
    _cargarPrefijos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _cargarPrefijos() async {
    setState(() => _cargandoPrefijos = true);
    final usados = await DataMaster().obtenerPrefijosUsados();
    if (mounted) {
      setState(() {
        _prefijosUsados = usados;
        _cargandoPrefijos = false;
      });
    }
  }

  Future<Map<String, Map<String, int>>> _obtenerStockPorCodigo(
    List<String> prefijos,
  ) async {
    return DataMaster().obtenerStockRealPorPrefijo(prefijos);
  }

  String _docId(Map<String, dynamic> d) => d['id']?.toString() ?? '';

  Future<void> _buscar() async {
    setState(() {
      _buscando = true;
      _buscado = false;
    });

    final usados = await DataMaster().obtenerPrefijosUsados();
    if (mounted) {
      setState(() {
        _prefijosUsados = usados;
        _cargandoPrefijos = false;
      });
    }

    List<Map<String, dynamic>> docs = await DataMaster().obtenerProductos();

    final nombre = _nombreController.text.trim().toLowerCase();
    if (nombre.isNotEmpty) {
      docs = docs.where((d) {
        final matchNombre = (d['nombre'] ?? '').toString().toLowerCase().contains(nombre);
        final matchCodigo = (d['codigo'] ?? '').toString().toLowerCase().contains(nombre);
        return matchNombre || matchCodigo;
      }).toList();
    }

    if (_conStock && !_sinStock) {
      docs = docs
          .where((d) => ((d['stockActual'] as num?)?.toInt() ?? 0) > 0)
          .toList();
    } else if (_sinStock && !_conStock) {
      docs = docs
          .where((d) => ((d['stockActual'] as num?)?.toInt() ?? 0) == 0)
          .toList();
    }

    final prefijosActivos = _prefijosSeleccionados.toList();

    if (prefijosActivos.isNotEmpty) {
      final stockPorCodigo = await _obtenerStockPorCodigo(prefijosActivos);
      final idsConCodigo = stockPorCodigo.keys.toSet();
      docs = docs.where((d) => idsConCodigo.contains(_docId(d))).toList();
      setState(() {
        _resultados = docs;
        _stockPorCodigo = stockPorCodigo;
        _prefijosActivos = prefijosActivos;
        _buscando = false;
        _buscado = true;
      });
    } else {
      setState(() {
        _resultados = docs;
        _stockPorCodigo = {};
        _prefijosActivos = [];
        _buscando = false;
        _buscado = true;
      });
    }
  }

  Future<void> _eliminar(Map<String, dynamic> data) async {
    final stock = (data['stockActual'] as num?)?.toInt() ?? 0;

    if (stock > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar, el producto tiene stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pinIngresado = await _pedirPin();
    if (pinIngresado == null) return;

    final pinGuardado = await DataMaster().obtenerPin();

    if (pinIngresado != pinGuardado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN incorrecto'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final id = _docId(data);
    await DataMaster().eliminarProducto(id: id);

    setState(() => _resultados.removeWhere((d) => _docId(d) == id));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<String?> _pedirPin() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingresa tu pin'),
        content: TextField(
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '****',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            counterText: '',
          ),
          onChanged: (v) => pin = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, pin),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editar(Map<String, dynamic> data) async {
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final codigoCtrl = TextEditingController(text: data['codigo'] ?? '');
    String errorDialog = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(
            'EDITAR PRODUCTO',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Color(0xFF0c6246)),
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Código (5 dígitos)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: const TextStyle(color: Color(0xFF0c6246)),
                  controller: codigoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: InputDecoration(
                    hintText: 'Ej: 65123',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (errorDialog.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorDialog,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
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
                final nombre = nombreCtrl.text.trim();
                final codigo = codigoCtrl.text.trim();
                if (nombre.isEmpty) {
                  setStateDialog(() => errorDialog = 'Ingresa el nombre');
                  return;
                }
                if (codigo.length != 5 || int.tryParse(codigo) == null) {
                  setStateDialog(
                      () => errorDialog = 'Ingresa los 5 dígitos del código');
                  return;
                }
                await DataMaster().actualizarProducto(
                  id: _docId(data),
                  nombre: nombre,
                  codigo: codigo,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _buscar();
              },
              child: const Text(
                'GUARDAR',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFiltros(),
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
                          color: AppColors.primary,
                        ),
                      ),
                    if (_buscado && _resultados.isEmpty)
                      const Center(
                        child: Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ..._resultados.map((doc) => _buildProductoItem(doc)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FILTROS',
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('Con stock', _conStock,
                (v) => setState(() => _conStock = v)),
            _buildChip('Sin stock', _sinStock,
                (v) => setState(() => _sinStock = v)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: ExpansionTile(
            title: Text(
              _prefijosSeleccionados.isEmpty
                  ? 'Filtrar por código'
                  : 'Código: ${(_prefijosSeleccionados.toList()..sort()).join(', ')}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.primary,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _cargandoPrefijos
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _prefijosUsados.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay códigos registrados',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _prefijosUsados.map((p) {
                              final seleccionado =
                                  _prefijosSeleccionados.contains(p);
                              return _buildChip(
                                'Código $p',
                                seleccionado,
                                (v) => setState(() {
                                  if (v) {
                                    _prefijosSeleccionados.add(p);
                                  } else {
                                    _prefijosSeleccionados.remove(p);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool seleccionado, Function(bool) onTap) {
    return GestureDetector(
      onTap: () => onTap(!seleccionado),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> data) {
    final id = _docId(data);

    int stockMostrar;
    String? etiquetaCodigo;

    if (_prefijosActivos.isNotEmpty && _stockPorCodigo.containsKey(id)) {
      stockMostrar = _prefijosActivos.fold(
          0, (sum, p) => sum + (_stockPorCodigo[id]![p] ?? 0));
      etiquetaCodigo = _prefijosActivos.join(', ');
    } else {
      stockMostrar = (data['stockActual'] as num?)?.toInt() ?? 0;
      etiquetaCodigo = null;
    }

    final bajoMinimo = stockMostrar < 1000;
    final codigoProducto = data['codigo']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bajoMinimo
              ? Colors.orange
              : AppColors.primary.withValues(alpha: 0.3),
          width: bajoMinimo ? 2 : 1,
        ),
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
                Row(
                  children: [
                    if (codigoProducto.isNotEmpty)
                      _buildTag('Cód: $codigoProducto'),
                    if (codigoProducto.isNotEmpty) const SizedBox(width: 8),
                    if (etiquetaCodigo != null)
                      _buildTag('Lote: $etiquetaCodigo'),
                    if (etiquetaCodigo != null) const SizedBox(width: 8),
                    _buildTag(
                      'Stock: $stockMostrar',
                      color: bajoMinimo ? Colors.orange : AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _editar(data),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _eliminar(data),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.primary,
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
            onPressed: () => context.go('/inventario/toma'),
          ),
          const SizedBox(width: 8),
          Text(
            'VER PRODUCTOS',
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