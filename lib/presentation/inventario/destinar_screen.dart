// ============================================================================
// destinar_screen.dart
//
// Pantalla NUEVA e INDEPENDIENTE del resto de la app.
//
// - Lee productos de DataMaster SOLO PARA MOSTRAR (obtenerProductos()),
//   nunca escribe nada en esa tabla ni en ninguna otra del schema principal.
// - Guarda los apartados en destinar_local_db.dart, una base SQLite aparte,
//   sin relación con Firestore ni con el schema versión 5.
// - El "disponible" que se muestra es meramente visual: stockActual real
//   del producto (fuente: DataMaster) menos la suma de apartados activos
//   en ESTA pantalla. Jamás se descuenta del stock real.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/data_master.dart';
import '../../core/data/destinar_local_db.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class DestinarScreen extends StatefulWidget {
  const DestinarScreen({super.key});

  @override
  State<DestinarScreen> createState() => _DestinarScreenState();
}

class _DestinarScreenState extends State<DestinarScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  Map<String, dynamic>? _productoSeleccionado;
  int _stockReal = 0;
  int _totalApartado = 0;
  int _disponible = 0;

  List<DestinarApartado> _apartadosDelProducto = [];
  List<DestinarApartado> _todosLosApartados = [];

  // Cuando la búsqueda por nombre trae varios resultados, se muestran acá
  // para que el usuario elija cuál es.
  List<Map<String, dynamic>> _resultadosBusqueda = [];

  bool _cargando = false;
  String? _errorBusqueda;
  String? _errorCantidad;

  @override
  void initState() {
    super.initState();
    _cargarTodosLosApartados();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _destinoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodosLosApartados() async {
    final lista = await DestinarLocalDb.instance.obtenerTodos();
    if (!mounted) return;
    setState(() => _todosLosApartados = lista);
  }

  Future<void> _buscarProducto() async {
    final texto = _busquedaController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _cargando = true;
      _errorBusqueda = null;
      _productoSeleccionado = null;
      _resultadosBusqueda = [];
      _errorCantidad = null;
    });

    try {
      // Lectura pura: DataMaster no se modifica de ninguna forma.
      final productos = await DataMaster().obtenerProductos();
      final textoLower = texto.toLowerCase();

      // 1) Match exacto por código: prioridad, selección directa.
      final porCodigo = productos.where(
        (p) => (p['codigo'] ?? '').toString().toLowerCase() == textoLower,
      );

      if (porCodigo.isNotEmpty) {
        await _seleccionarProducto(porCodigo.first);
        return;
      }

      // 2) Sin match de código: buscar por nombre (coincidencia parcial).
      final porNombre = productos
          .where((p) =>
              (p['nombre'] ?? '').toString().toLowerCase().contains(textoLower))
          .toList();

      if (porNombre.isEmpty) {
        setState(() {
          _errorBusqueda = 'No se encontró ningún producto con ese código o nombre';
          _cargando = false;
        });
        return;
      }

      if (porNombre.length == 1) {
        await _seleccionarProducto(porNombre.first);
        return;
      }

      // Varias coincidencias por nombre: se muestran para elegir.
      setState(() {
        _resultadosBusqueda = porNombre;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _errorBusqueda = 'Error al buscar el producto';
        _cargando = false;
      });
    }
  }

  Future<void> _seleccionarProducto(Map<String, dynamic> producto) async {
    final stockReal = (producto['stockActual'] as num?)?.toInt() ?? 0;
    final apartadosProducto = await DestinarLocalDb.instance
        .obtenerPorCodigo(producto['codigo'].toString());

    int totalApartado = 0;
    for (final a in apartadosProducto) {
      totalApartado += a.cantidad;
    }

    setState(() {
      _productoSeleccionado = producto;
      _resultadosBusqueda = [];
      _stockReal = stockReal;
      _totalApartado = totalApartado;
      _disponible = stockReal - totalApartado;
      _apartadosDelProducto = apartadosProducto;
      _cargando = false;
    });
  }

  Future<void> _guardarApartado() async {
    final producto = _productoSeleccionado;
    if (producto == null) return;

    final destino = _destinoController.text.trim();
    final cantidadTexto = _cantidadController.text.trim();

    if (destino.isEmpty) {
      setState(() => _errorCantidad = 'Escribí un destino');
      return;
    }

    final cantidad = int.tryParse(cantidadTexto);
    if (cantidad == null || cantidad <= 0) {
      setState(() => _errorCantidad = 'Ingresá una cantidad válida');
      return;
    }

    if (cantidad > _disponible) {
      setState(() =>
          _errorCantidad = 'Solo hay $_disponible disponibles para destinar');
      return;
    }

    setState(() => _errorCantidad = null);

    final nuevoApartado = DestinarApartado(
      codigoProducto: producto['codigo'].toString(),
      nombreProducto: producto['nombre'].toString(),
      destino: destino,
      cantidad: cantidad,
      fecha: DateTime.now().toIso8601String(),
    );

    await DestinarLocalDb.instance.insertarApartado(nuevoApartado);

    _destinoController.clear();
    _cantidadController.clear();

    // Recalcular todo para reflejar el nuevo apartado
    await _buscarProducto();
    await _cargarTodosLosApartados();
  }

  Future<void> _eliminarApartado(DestinarApartado apartado) async {
    if (apartado.id == null) return;
    await DestinarLocalDb.instance.eliminarApartado(apartado.id!);

    // Si el apartado eliminado pertenece al producto actualmente
    // seleccionado, recalculamos el disponible en pantalla.
    if (_productoSeleccionado != null &&
        _productoSeleccionado!['codigo'].toString() ==
            apartado.codigoProducto) {
      await _buscarProducto();
    }
    await _cargarTodosLosApartados();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.pop();
      },
      child: Scaffold(
        body: Column(
          children: [
            _Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvisoLocal(),
                    const SizedBox(height: 16),
                    _buildBuscador(),
                    if (_errorBusqueda != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorBusqueda!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (_resultadosBusqueda.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildResultadosBusqueda(),
                    ],
                    if (_productoSeleccionado != null) ...[
                      const SizedBox(height: 20),
                      _buildProductoInfo(),
                      const SizedBox(height: 20),
                      _buildFormularioApartado(),
                      const SizedBox(height: 24),
                      if (_apartadosDelProducto.isNotEmpty)
                        _buildListaApartadosProducto(),
                    ],
                    const SizedBox(height: 32),
                    _buildTodosLosApartados(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisoLocal() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta pantalla es solo una libreta de apartados. '
              'No se sincroniza con Firebase y no modifica el stock real.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _busquedaController,
            decoration: const InputDecoration(
              labelText: 'Código o nombre de producto',
              border: OutlineInputBorder(),
              hintText: 'Ej: 65123 u Oximed',
            ),
            onSubmitted: (_) => _buscarProducto(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _cargando ? null : _buscarProducto,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildResultadosBusqueda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_resultadosBusqueda.length} productos encontrados — elegí uno:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        ..._resultadosBusqueda.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(p['nombre'].toString()),
                subtitle: Text('Código: ${p['codigo']}'),
                onTap: () => _seleccionarProducto(p),
              ),
            )),
      ],
    );
  }

  Widget _buildProductoInfo() {
    final nombre = _productoSeleccionado!['nombre'].toString();
    final codigo = _productoSeleccionado!['codigo'].toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            'Código: $codigo',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('Stock real', '$_stockReal', Colors.black87),
              const SizedBox(width: 10),
              _statChip('Apartado', '$_totalApartado', Colors.orange),
              const SizedBox(width: 10),
              _statChip(
                'Disponible',
                '$_disponible',
                _disponible > 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioApartado() {
    final bool sinDisponible = _disponible <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nuevo apartado',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _destinoController,
          decoration: const InputDecoration(
            labelText: 'Destino',
            hintText: 'Ej: Perú',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _cantidadController,
          keyboardType: TextInputType.number,
          enabled: !sinDisponible,
          decoration: InputDecoration(
            labelText: 'Cantidad',
            hintText: sinDisponible ? 'Sin disponible' : 'Ej: 3000',
            border: const OutlineInputBorder(),
          ),
        ),
        if (_errorCantidad != null) ...[
          const SizedBox(height: 6),
          Text(_errorCantidad!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: sinDisponible ? null : _guardarApartado,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('APARTAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaApartadosProducto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apartados de este producto',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ..._apartadosDelProducto.map((a) => _apartadoTile(a)),
      ],
    );
  }

  Widget _buildTodosLosApartados() {
    if (_todosLosApartados.isEmpty) {
      return const SizedBox.shrink();
    }

    // Agrupar por nombre de producto para mostrar totales.
    final Map<String, List<DestinarApartado>> agrupado = {};
    for (final a in _todosLosApartados) {
      agrupado.putIfAbsent(a.nombreProducto, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Todos los apartados',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...agrupado.entries.map((entry) {
          final total = entry.value.fold<int>(0, (s, a) => s + a.cantidad);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}  —  total: $total',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ...entry.value.map((a) => _apartadoTile(a)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _apartadoTile(DestinarApartado a) {
    final fecha = DateTime.tryParse(a.fecha);
    final fechaTexto = fecha != null
        ? '${fecha.day.toString().padLeft(2, '0')}/'
            '${fecha.month.toString().padLeft(2, '0')}/'
            '${fecha.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (_) => _confirmarEliminar(a),
          ),
          Expanded(
            child: Text(
              '${a.destino} — ${a.cantidad}  ($fechaTexto)',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(DestinarApartado a) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar apartado'),
        content: Text(
          '¿Eliminar el apartado de ${a.cantidad} para "${a.destino}"?\n\n'
          'Esto solo borra la anotación de este dispositivo. '
          'No afecta el stock real ni Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _eliminarApartado(a);
    }
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            'DESTINAR',
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
