import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';

class RetirosDiaScreen extends StatefulWidget {
  const RetirosDiaScreen({super.key});

  @override
  State<RetirosDiaScreen> createState() => _RetirosDiaScreenState();
}

class _RetirosDiaScreenState extends State<RetirosDiaScreen> {
  bool _generando = false;
  List<QueryDocumentSnapshot> _retiros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHoy();
  }

  Future<void> _cargarHoy() async {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia =
        DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('retiros')
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha',
            isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .orderBy('fecha', descending: false)
        .get();

    setState(() {
      _retiros = snapshot.docs;
      _cargando = false;
    });
  }

  String _formatHora(Timestamp? ts) {
    if (ts == null) return '-';
    final fecha = ts.toDate();
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
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
                    'DEPÓSITO DE ETIQUETAS - GALMEDIC',
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
                'RETIROS DEL DÍA',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#0c6246'),
                ),
              ),
              pw.Divider(color: PdfColor.fromHex('#0c6246')),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) => [
            if (_retiros.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No hubo retiros hoy',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#0c6246'),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(0.8),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1.2),
                  7: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#0c6246'),
                    ),
                    children: [
                      'HORA',
                      'PRODUCTO',
                      'TIPO',
                      'ID',
                      'CANTIDAD',
                      'COMPAÑERO',
                      'LOTE',
                      'DESTINO',
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
                  ..._retiros.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _formatHora(data['fecha'] as Timestamp?),
                        data['productoNombre'] ?? '',
                        data['tipo'] ?? '',
                        data['idioma'] ?? '',
                        (data['cantidadEntregada'] ?? 0).toString(),
                        data['companero'] ?? '',
                        data['lote'] ?? '',
                        data['destino'] ?? '',
                      ]
                          .map((v) => pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  v,
                                  style:
                                      const pw.TextStyle(fontSize: 9),
                                ),
                              ))
                          .toList(),
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Total de retiros: ${_retiros.length}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0c6246'),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'retiros_dia_$fechaStr.pdf',
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
          if (_cargando)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_retiros.length} retiro${_retiros.length != 1 ? 's' : ''} hoy',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_retiros.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _generando ? null : _generarPDF,
                      icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18),
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
            ),
            Expanded(
              child: _retiros.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            color: AppColors.primary,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sin retiros hoy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      itemCount: _retiros.length,
                      itemBuilder: (context, index) {
                        final data = _retiros[index].data()
                            as Map<String, dynamic>;
                        final hora = _formatHora(
                            data['fecha'] as Timestamp?);
                        final estado = data['estado'] ?? 'pendiente';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: estado == 'cerrado'
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.orange,
                              width: estado == 'cerrado' ? 1 : 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hora,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
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
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: estado == 'cerrado'
                                          ? Colors.green
                                              .withOpacity(0.1)
                                          : Colors.orange
                                              .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                        color: estado == 'cerrado'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    child: Text(
                                      estado == 'cerrado'
                                          ? 'CERRADO'
                                          : 'PENDIENTE',
                                      style: TextStyle(
                                        color: estado == 'cerrado'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
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
                                  _buildTag(data['tipo'] ?? ''),
                                  _buildTag(data['idioma'] ?? ''),
                                  _buildTag(
                                      '📤 ${data['cantidadEntregada'] ?? 0}'),
                                  _buildTag(
                                      '👤 ${data['companero'] ?? ''}'),
                                  _buildTag(
                                      '📦 ${data['lote'] ?? ''}'),
                                  _buildTag(
                                      '🌍 ${data['destino'] ?? ''}'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
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
            'RETIROS DEL DÍA',
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