import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'database_helper.dart'; 
import 'category_detail_screen.dart'; 
import 'site_analytics_screen.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteName;

  const SiteDetailScreen({super.key, required this.siteName});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  double _totalSiteExpense = 0.0;
  bool _isLoadingTotal = true;
  
  final Map<String, double> _categoryTotals = {};

  final List<Map<String, dynamic>> _categories = const [
    {'title': 'Material', 'subtitle': 'Sand, Agg, Steel, Cement, Bitumin', 'icon': Icons.inventory_2, 'color': Colors.orange},
    {'title': 'Labour', 'subtitle': 'Worker daily wages & details', 'icon': Icons.engineering, 'color': Colors.blue},
    {'title': 'Equipment', 'subtitle': 'JCB, Poclain, Tractor, Tanker', 'icon': Icons.local_shipping, 'color': Colors.green},
    {'title': 'Vendor', 'subtitle': 'Add vendor, traders, enterprise', 'icon': Icons.store, 'color': Colors.purple},
    {'title': 'Other Expenses', 'subtitle': 'Miscellaneous site expenses', 'icon': Icons.receipt_long, 'color': Colors.redAccent},
  ];

  @override
  void initState() {
    super.initState();
    _loadSiteData();
  }

  Future<void> _loadSiteData() async {
    double grandTotal = 0.0;
    Map<String, double> tempTotals = {};

    for (var cat in _categories) {
      String catTitle = cat['title'];
      final expenses = await DatabaseHelper.instance.getExpenses(widget.siteName, catTitle);
      double catTotal = 0.0;
      
      for (var exp in expenses) {
        catTotal += double.tryParse(exp['amount'].toString()) ?? 0.0;
      }
      
      tempTotals[catTitle] = catTotal;
      grandTotal += catTotal;
    }

    if (mounted) {
      setState(() {
        _totalSiteExpense = grandTotal;
        _categoryTotals.clear();
        _categoryTotals.addAll(tempTotals);
        _isLoadingTotal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.siteName, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_rounded, color: Color(0xFF3B82F6), size: 28),
            tooltip: 'View Analytics & Pie Chart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SiteAnalyticsScreen(siteName: widget.siteName),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Site total Expense', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6),
                    Text('Total Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                _isLoadingTotal
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        '₹ $_totalSiteExpense',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                      ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                String catTitle = cat['title'];
                double catTotal = _categoryTotals[catTitle] ?? 0.0;
                Color catColor = cat['color'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(
                              siteName: widget.siteName,
                              categoryTitle: catTitle,
                            ),
                          ),
                        ).then((_) => _loadSiteData());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(cat['icon'], color: catColor, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(catTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text(cat['subtitle'], style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹ $catTotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: catColor)),
                                const SizedBox(height: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}