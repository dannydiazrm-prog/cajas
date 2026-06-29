import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/data_master.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class AjusteInventarioScreen extends StatefulWidget {
  const AjusteInventarioScreen({super.key});

  @override
  State<AjusteInventarioScreen> createState() =>
      _AjusteInventarioScreenState();
}

class _AjusteInventarioScreenState extends State<AjusteInventarioScreen> {
  final _nombreController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _buscado = false;
  Map<String, dynamic>? _productoSeleccionado;

  List<Map<String, dynamic>> _combinaciones = [];
  Map<String, dynamic>? _combinacionSeleccionada;
  Map<String, String> _nombresDestinos = {};

  String? _tipoAjuste;
  final _cantidadController = TextEditingController();
  String? _motivo;
  final _otroController = TextEditingController();
  bool _guardando = false;
  String _error = '';

  final List<String> _motivosResta = [
    'Producto dañado',
    'Producto vencido/viejo',
    'Pérdida',
    'Error de conteo',
    'Otro',
  ];

  final List<String> _motivosSuma = [
    'Diferencia de conteo',
    'Producto encontrado',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _cargarNombresDestinos();
  }

  Future<void> _cargarNombresDestinos() async {
    final destinos = await DataMaster().obtenerDestinos();
    setState(() {
      _nombresDestinos = {
        for (final d in destinos) d['id'].toString(): d['nombre'].toString(),
      };
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _otroController.dispose();
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

    setState(() {
      _resultados = docs;
      _buscando = false;
      _buscado = true;
    });
  }

  Future<void> _seleccionarProducto(Map<String, dynamic> producto) async {
    final combinaciones = await DataMaster()
        .obtenerCombinacionesRecepcion(producto['id'].toString());

    setState(() {
      _combinaciones = combinaciones;
      _combinacionSeleccionada = null;
      _productoSeleccionado = producto;
      _buscado = false;
      _resultados = [];
      _nombreController.clear();
      _tipoAjuste = null;
      _motivo = null;
      _cantidadController.clear();
      _otroController.clear();
      _error = '';
    });
  }

  String _nombresCombinacion(List<String> ids) {
    final nombres = ids.map((id) => _nombresDestinos[id] ?? id).toList();
    return nombres.join(' · ');
  }

  Future<void> _confirmar() async {
    final cantidad = int.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'Ingresa una cantidad válida');
      return;
    }
    if (_tipoAjuste == null) {
      setState(() => _error = 'Selecciona si es suma o resta');
      return;
    }
    if (_combinacionSeleccionada == null) {
      setState(() => _error = 'Selecciona un destino');
      return;
    }
    if (_motivo == null) {
      setState(() => _error = 'Selecciona un motivo');
      return;
    }
    if (_motivo == 'Otro' && _otroController.text.trim().isEmpty) {
      setState(() => _error = 'Describe el motivo');
      return;
    }

    final data = _productoSeleccionado!;

    if (_tipoAjuste == 'resta') {
      final disponible =
          (_combinacionSeleccionada!['cantidadActual'] as num?)?.toInt() ?? 0;
      if (cantidad > disponible) {
        setState(() =>
            _error = 'Stock insuficiente en este destino. Disponibles: $disponible');
        return;
      }
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      final destinosIds = List<String>.from(
          _combinacionSeleccionada!['destinosIds'] as List? ?? []);
      final recepcionIds = List<String>.from(
          _combinacionSeleccionada!['recepcionIds'] as List? ?? []);
      final motivoFinal =
          _motivo == 'Otro' ? _otroController.text.trim() : _motivo!;

      await DataMaster().registrarAjuste(
        tipo: 'ajuste_manual',
        tipoAjuste: _tipoAjuste!,
        productoId: data['id'].toString(),
        productoNombre: data['nombre'].toString(),
        tipoProducto: data['tipo']?.toString() ?? '',
        idioma: data['idioma']?.toString() ?? '',
        cantidad: cantidad,
        motivo: motivoFinal,
        destinosIds: destinosIds,
        recepcionIds: recepcionIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajuste registrado correctamente'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/ajustes');
      }
    } catch (e) {
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
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
                child: _productoSeleccionado == null
                    ? _buildBusqueda()
                    : _buildFormulario(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECCIONA EL PRODUCTO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
            child: CircularProgressIndicator(color: AppColors.primary),
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
        ..._resultados.map((data) {
          final stock = (data['stockActual'] as num?)?.toInt() ?? 0;
          final codigo = data['codigo']?.toString() ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _seleccionarProducto(data),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                              if (codigo.isNotEmpty)
                                _buildTag('Cód: $codigo'),
                              if (codigo.isNotEmpty)
                                const SizedBox(width: 8),
                              _buildTag(
                                'Stock: $stock',
                                color: stock < 1000
                                    ? Colors.orange
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFormulario() {
    final data = _productoSeleccionado!;
    final stock = (data['stockActual'] as num?)?.toInt() ?? 0;
    final codigo = data['codigo']?.toString() ?? '';
    final motivos = _tipoAjuste == 'suma' ? _motivosSuma : _motivosResta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRODUCTO SELECCIONADO',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['nombre'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (codigo.isNotEmpty)
                          _buildTagBlanco('Cód: $codigo'),
                        if (codigo.isNotEmpty) const SizedBox(width: 8),
                        _buildTagBlanco('Stock actual: $stock'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() {
                  _productoSeleccionado = null;
                  _combinaciones = [];
                  _combinacionSeleccionada = null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'TIPO DE AJUSTE',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _tipoAjuste = 'suma';
                  _motivo = null;
                  _combinacionSeleccionada = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  decoration: BoxDecoration(
                    color: _tipoAjuste == 'suma'
                        ? Colors.green
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: _tipoAjuste == 'suma'
                            ? Colors.white
                            : Colors.green,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SUMAR',
                        style: TextStyle(
                          color: _tipoAjuste == 'suma'
                              ? Colors.white
                              : Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _tipoAjuste = 'resta';
                  _motivo = null;
                  _combinacionSeleccionada = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 70,
                  decoration: BoxDecoration(
                    color: _tipoAjuste == 'resta'
                        ? Colors.red
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove_circle_outline,
                        color: _tipoAjuste == 'resta'
                            ? Colors.white
                            : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RESTAR',
                        style: TextStyle(
                          color: _tipoAjuste == 'resta'
                              ? Colors.white
                              : Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_tipoAjuste != null) ...[
          const Text(
            'DESTINO',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seleccioná el destino al que pertenece este ajuste',
            style: TextStyle(color: AppColors.primary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (_combinaciones.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'Este producto no tiene recepciones registradas. Realizá una recepción primero.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              children: _combinaciones.map((combinacion) {
                final ids = List<String>.from(
                    combinacion['destinosIds'] as List);
                final clave = combinacion['clave'] as String;
                final seleccionado =
                    _combinacionSeleccionada?['clave'] == clave;
                final disponible =
                    (combinacion['cantidadActual'] as num?)?.toInt() ?? 0;
                final prefijo =
                    combinacion['prefijo']?.toString() ?? '';

                return GestureDetector(
                  onTap: () => setState(
                      () => _combinacionSeleccionada = combinacion),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: seleccionado
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        width: seleccionado ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nombresCombinacion(ids),
                                style: TextStyle(
                                  color: seleccionado
                                      ? Colors.white
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cód. $prefijo · Disponibles: $disponible',
                                style: TextStyle(
                                  color: seleccionado
                                      ? Colors.white70
                                      : Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (seleccionado)
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

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
            decoration: InputDecoration(
              hintText: 'Ej: 500',
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
          const SizedBox(height: 24),

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: motivos.map((m) {
              final seleccionado = _motivo == m;
              return GestureDetector(
                onTap: () => setState(() => _motivo = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        seleccionado ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    m,
                    style: TextStyle(
                      color: seleccionado
                          ? Colors.white
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_motivo == 'Otro') ...[
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Color(0xFF0c6246)),
              controller: _otroController,
              decoration: InputDecoration(
                hintText: 'Describí el motivo...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'CONFIRMAR AJUSTE',
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

  Widget _buildTagBlanco(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
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
            onPressed: () => context.go('/ajustes'),
          ),
          const SizedBox(width: 8),
          Text(
            'AJUSTE DE INVENTARIO',
            style: TextStyle(
              color: Colors.white,
              fontSize: Breakpoints.isMobile(context) ? 18 : 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}