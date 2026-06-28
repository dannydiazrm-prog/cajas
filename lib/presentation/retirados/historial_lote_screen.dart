import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/data/data_master.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class HistorialLoteScreen extends StatefulWidget {
  const HistorialLoteScreen({super.key});

  @override
  State<HistorialLoteScreen> createState() => _HistorialLoteScreenState();
}

class _HistorialLoteScreenState extends State<HistorialLoteScreen> {
  final _loteController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _buscado = false;
  bool _generando = false;

  // Panel de perdidos
  String? _expandidoId;
  final _perdidosController = TextEditingController();
  bool _guardandoPerdidos = false;

  @override
  void dispose() {
    _loteController.dispose();
    _perdidosController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final lote = _loteController.text.trim();
    if (lote.isEmpty) return;

    setState(() {
      _buscando = true;
      _buscado = false;
      _expandidoId = null;
    });

    final docs = await DataMaster().obtenerRetiros(lote: lote);

    docs.sort((a, b) {
      final fechaA =
          DateTime.tryParse(a['fecha'] as String? ?? '') ?? DateTime(2000);
      final fechaB =
          DateTime.tryParse(b['fecha'] as String? ?? '') ?? DateTime(2000);
      return fechaB.compareTo(fechaA);
    });

    setState(() {
      _resultados = docs;
      _buscando = false;
      _buscado = true;
    });
  }

  Future<void> _registrarPerdidos(Map<String, dynamic> data) async {
    final cantidad = int.tryParse(_perdidosController.text.trim());

    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardandoPerdidos = true);

    try {
      final retiroId = data['id']?.toString() ?? '';
      final perdidosActuales = (data['cantidadDevuelta'] as num?)?.toInt() ?? 0;
      final nuevosPerdidos = perdidosActuales + cantidad;

      await DataMaster().cerrarRetiro(
        retiroId: retiroId,
        productoId: data['productoId']?.toString() ?? '',
        destinoId: data['destinoId']?.toString() ?? '',
        cantidadDevuelta: nuevosPerdidos,
        motivoCierre: 'Pérdida en calibración',
      );

      setState(() {
        _expandidoId = null;
        _perdidosController.clear();
        _guardandoPerdidos = false;
      });

      await _buscar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cantidad cajas perdidas registradas'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardandoPerdidos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFechaHora(String? fechaStr) {
    if (fechaStr == null) return '-';
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return '-';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _generarPDF() async {
    setState(() => _generando = true);

    try {
      final pdf = pw.Document();
      final fecha = DateTime.now();
      final fechaStr = _formatFecha(fecha);
      final lote = _loteController.text.trim();

      int totalEntregado = 0;
      int totalPerdidos = 0;
      for (final data in _resultados) {
        totalEntregado += (data['cantidadEntregada'] ?? 0) as int;
        totalPerdidos += (data['cantidadDevuelta'] ?? 0) as int;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DEPÓSITO DE CAJAS - GALMEDIC',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0c6246'),
                    ),
                  ),
                  pw.Text(
                    fechaStr,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'HISTORIAL - LOTE: $lote',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0c6246'),
                ),
              ),
              pw.Divider(color: PdfColor.fromHex('#0c6246')),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => [
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#0c6246'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0c6246'),
                  ),
                  children: [
                    'PRODUCTO',
                    'COMPAÑERO',
                    'RETIRADO',
                    'PERDIDOS',
                    'FECHA',
                  ]
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                ..._resultados.map((data) {
                  final perdidos = (data['cantidadDevuelta'] ?? 0) as int;
                  return pw.TableRow(
                    children: [
                      data['productoNombre'] ?? '',
                      data['companero'] ?? '',
                      (data['cantidadEntregada'] ?? 0).toString(),
                      perdidos > 0 ? perdidos.toString() : '-',
                      _formatFechaHora(data['fecha'] as String?),
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                v,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#0c6246')),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESUMEN DEL LOTE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0c6246'),
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Total movimientos: ${_resultados.length}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Total retirado: $totalEntregado cajas',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Total perdidos: $totalPerdidos cajas',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'lote_${lote}_$fechaStr.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _generando = false);
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
                    const Text(
                      'BUSCAR POR LOTE',
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
                          child: TextField(
                            style: const TextStyle(color: Color(0xFF0c6246)),
                            controller: _loteController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Número de lote',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
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
                            onSubmitted: (_) => _buscar(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _buscando ? null : _buscar,
                            child: _buscando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'BUSCAR',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_buscado) ...[
                      if (_resultados.isEmpty)
                        const Center(
                          child: Text(
                            'No se encontraron movimientos para ese lote',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        _buildResumen(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_resultados.length} movimiento${_resultados.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _generando ? null : _generarPDF,
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 18,
                              ),
                              label: _generando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('PDF'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._resultados.map((data) => _buildRetiroItem(data)),
                      ],
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

  Widget _buildRetiroItem(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';
    final expandido = _expandidoId == id;
    final perdidos = (data['cantidadDevuelta'] as num?)?.toInt() ?? 0;
    final retirado = (data['cantidadEntregada'] as num?)?.toInt() ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expandido
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          width: expandido ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (_expandidoId == id) {
                  _expandidoId = null;
                } else {
                  _expandidoId = id;
                  _perdidosController.clear();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['productoNombre'] ?? '',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if ((data['companero'] ?? '').toString().isNotEmpty)
                              _buildTag('👤 ${data['companero']}'),
                            _buildTag('📤 Retirado: $retirado'),
                            if (perdidos > 0)
                              _buildTag(
                                '⚠️ Perdidos: $perdidos',
                                color: Colors.orange,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFechaHora(data['fecha'] as String?),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expandido ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (expandido) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perdidos > 0
                                ? 'Ya hay $perdidos cajas perdidas registradas en este retiro. Podés agregar más.'
                                : 'Registrá las cajas dañadas en calibración. Se descontarán del stock.',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CAJAS PERDIDAS',
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
                    controller: _perdidosController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ej: 20',
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _guardandoPerdidos
                          ? null
                          : () => _registrarPerdidos(data),
                      child: _guardandoPerdidos
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'REGISTRAR PERDIDOS',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumen() {
    int totalEntregado = 0;
    int totalPerdidos = 0;

    for (final data in _resultados) {
      totalEntregado += (data['cantidadEntregada'] ?? 0) as int;
      totalPerdidos += (data['cantidadDevuelta'] ?? 0) as int;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOTE: ${_loteController.text.trim()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResumenItem(
                    'MOVIMIENTOS', _resultados.length.toString()),
              ),
              Expanded(
                child:
                    _buildResumenItem('RETIRADO', totalEntregado.toString()),
              ),
              Expanded(
                child: _buildResumenItem('PERDIDOS', totalPerdidos.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.primary,
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
            'HISTORIAL',
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