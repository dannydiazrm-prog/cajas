import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/data/data_master.dart';

class ControlStockScreen extends StatefulWidget {
  const ControlStockScreen({super.key});

  @override
  State<ControlStockScreen> createState() => _ControlStockScreenState();
}
class _ControlStockScreenState extends State<ControlStockScreen>
    with SingleTickerProviderStateMixin {
  bool _generando = false;
  late TabController _tabController;
  final Map<int, int> _paginas = {0: 0, 1: 0, 2: 0};
  static const int _porPagina = 10;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _colorSemaforo(int stock) {
    if (stock == 0) return Colors.red;
    if (stock <= 500) return Colors.orange;
    return Colors.amber;
  }

  String _etiquetaSemaforo(int stock) {
    if (stock == 0) return 'SIN STOCK';
    if (stock <= 500) return 'CRÍTICO';
    return 'BAJO';
  }

  Future<List<Map<String, dynamic>>> _cargarProductosBajos() async {
    final todos = await DataMaster().obtenerProductos();

    final bajos = todos.where((p) {
      final stock = (p['stockActual'] as num?)?.toInt() ?? 0;
      return stock < 1000;
    }).toList();

    bajos.sort((a, b) {
      final stockA = (a['stockActual'] as num?)?.toInt() ?? 0;
      final stockB = (b['stockActual'] as num?)?.toInt() ?? 0;
      return stockA.compareTo(stockB);
    });

    return bajos;
  }

  List<Map<String, dynamic>> _filtrarPorTab(
      List<Map<String, dynamic>> docs, int tabIndex) {
    return docs.where((p) {
      final stock = (p['stockActual'] as num?)?.toInt() ?? 0;
      if (tabIndex == 0) return stock == 0;
      if (tabIndex == 1) return stock > 0 && stock <= 500;
      return stock > 500 && stock < 1000;
    }).toList();
  }

  Widget _buildListaPaginada(List<Map<String, dynamic>> items, int tabIndex) {
    final pagina = _paginas[tabIndex] ?? 0;
    final totalPaginas = (items.length / _porPagina).ceil();
    final inicio = pagina * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, items.length);
    final itemsPagina = items.sublist(inicio, fin);

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Sin productos en esta categoría',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itemsPagina.length,
            itemBuilder: (context, index) {
              final data = itemsPagina[index];
              final stock = (data['stockActual'] as num?)?.toInt() ?? 0;
              final color = _colorSemaforo(stock);
              final estado = _etiquetaSemaforo(stock);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
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
                          if ((data['codigo'] ?? '').toString().isNotEmpty)
                            _buildTag('Cód: ${data['codigo']}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$stock',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
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
        if (totalPaginas > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: pagina > 0
                      ? () => setState(() => _paginas[tabIndex] = pagina - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  color: AppColors.primary,
                ),
                Text(
                  '${pagina + 1} / $totalPaginas',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  onPressed: pagina < totalPaginas - 1
                      ? () => setState(() => _paginas[tabIndex] = pagina + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _generarPDF(List<Map<String, dynamic>> docs) async {
    setState(() => _generando = true);

    try {
      final pdf = pw.Document();
      final fecha = DateTime.now();
      final fechaStr =
          '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
      final horaStr =
          '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

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
                    '$fechaStr $horaStr',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'ALERTA DE STOCK BAJO',
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
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#0c6246'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0c6246'),
                  ),
                  children: [
                    'NOMBRE',
                    'CÓDIGO',
                    'STOCK ACTUAL',
                    'ESTADO',
                  ]
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              h,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                ...docs.map((data) {
                  final stock = (data['stockActual'] as num?)?.toInt() ?? 0;
                  String estado;
                  if (stock == 0) {
                    estado = 'SIN STOCK';
                  } else if (stock <= 500) {
                    estado = 'CRITICO';
                  } else {
                    estado = 'BAJO';
                  }
                  return pw.TableRow(
                    children: [
                      data['nombre'] ?? '',
                      data['codigo'] ?? '',
                      stock.toString(),
                      estado,
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                v,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Total de productos con stock bajo: ${docs.length}',
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
        name: 'stock_bajo_$fechaStr.pdf',
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cargarProductosBajos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return Center(
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
                          'Todo el stock está en orden',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Todos los productos superan las 1.000 unidades',
                          style: TextStyle(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sinStock = _filtrarPorTab(docs, 0);
                final critico = _filtrarPorTab(docs, 1);
                final bajo = _filtrarPorTab(docs, 2);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${docs.length} productos con stock bajo',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _generando ? null : () => _generarPDF(docs),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                            label: _generando
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('PDF'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.onSurfaceDim,
                      indicatorColor: AppColors.primary,
                      dividerColor: AppColors.border,
                      tabs: [
                        Tab(text: 'Sin stock (${sinStock.length})'),
                        Tab(text: 'Crítico (${critico.length})'),
                        Tab(text: 'Bajo (${bajo.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListaPaginada(sinStock, 0),
                          _buildListaPaginada(critico, 1),
                          _buildListaPaginada(bajo, 2),
                        ],
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
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
            'CONTROL DE STOCK',
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

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;

  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
