import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class SiteAnalyticsScreen extends StatefulWidget {
  final String siteName;

  const SiteAnalyticsScreen({super.key, required this.siteName});

  @override
  State<SiteAnalyticsScreen> createState() => _SiteAnalyticsScreenState();
}

class _SiteAnalyticsScreenState extends State<SiteAnalyticsScreen> {
  bool _isLoading = true;
  double _totalExpense = 0.0;
  
  // 👉 Fixed to 'Other' to match CategoryDetailScreen
  Map<String, double> _categoryExpenses = {
    'Material': 0.0,
    'Labour': 0.0,
    'Equipment': 0.0,
    'Vendor': 0.0,
    'Other': 0.0,
  };

  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    List<String> categories = ['Material', 'Labour', 'Equipment', 'Vendor', 'Other'];
    Map<String, double> tempMap = {};
    double grandTotal = 0.0;

    for (String cat in categories) {
      final expenses = await DatabaseHelper.instance.getExpenses(widget.siteName, cat);
      double catTotal = 0.0;
      for (var exp in expenses) {
        catTotal += double.tryParse(exp['amount'].toString()) ?? 0.0;
      }
      tempMap[cat] = catTotal;
      grandTotal += catTotal;
    }

    if (mounted) {
      setState(() {
        _categoryExpenses = tempMap;
        _totalExpense = grandTotal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${widget.siteName} - Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _totalExpense == 0.0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No expense data available for charts yet!', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Overall Site Outflow', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                                SizedBox(height: 6),
                                Text('Total Spent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            Text(
                              '₹ $_totalExpense',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        'Expense Distribution (Pie Chart)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 220,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: showingSections(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                makeIndicator(Colors.orange, 'Material', _categoryExpenses['Material']!),
                                makeIndicator(Colors.blue, 'Labour', _categoryExpenses['Labour']!),
                                makeIndicator(Colors.green, 'Equipment', _categoryExpenses['Equipment']!),
                                makeIndicator(Colors.purple, 'Vendor', _categoryExpenses['Vendor']!),
                                makeIndicator(Colors.redAccent, 'Other', _categoryExpenses['Other']!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> showingSections() {
    List<MapEntry<String, Color>> categories = [
      const MapEntry('Material', Colors.orange),
      const MapEntry('Labour', Colors.blue),
      const MapEntry('Equipment', Colors.green),
      const MapEntry('Vendor', Colors.purple),
      const MapEntry('Other', Colors.redAccent),
    ];

    return categories.asMap().map((index, entry) {
      bool isTouched = index == touchedIndex;
      double fontSize = isTouched ? 16.0 : 12.0;
      double radius = isTouched ? 60.0 : 50.0;
      double value = _categoryExpenses[entry.key] ?? 0.0;

      return MapEntry(
        index,
        PieChartSectionData(
          color: entry.value,
          value: value,
          title: value > 0 ? '₹${value.toInt()}' : '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }).values.toList();
  }

  Widget makeIndicator(Color color, String title, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$title (₹${amount.toInt()})',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}