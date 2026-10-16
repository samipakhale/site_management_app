import 'package:flutter/material.dart';
import 'home_screen.dart';
// Tumchya actual database file che naav ithe dya (e.g. database_helper.dart)
import 'database_helper.dart'; // .txt aivaji .dart karun baghimport 'home_screen.dart';

class SiteModel {
  final String siteName;
  final String status;
  final double budget;
  final double receivedAmount;

  SiteModel({
    required this.siteName,
    required this.status,
    required this.budget,
    required this.receivedAmount,
  });
}

class CategoryExpenseSummary {
  final double materialTotal;
  final double labourTotal;
  final double vendorTotal;
  final double equipmentTotal;
  final double extraTotal;

  CategoryExpenseSummary({
    required this.materialTotal,
    required this.labourTotal,
    required this.vendorTotal,
    required this.equipmentTotal,
    required this.extraTotal,
  });

  double get grandTotal =>
      materialTotal + labourTotal + vendorTotal + equipmentTotal + extraTotal;
}

class ClientSummaryDashboardScreen extends StatefulWidget {
  final String clientName;
  final String defaultSiteName;

  const ClientSummaryDashboardScreen({
    super.key,
    this.clientName = "Mahesh Sir",
    this.defaultSiteName = "Shree Niwas Residency",
  });

  @override
  State<ClientSummaryDashboardScreen> createState() =>
      _ClientSummaryDashboardScreenState();
}

class _ClientSummaryDashboardScreenState
    extends State<ClientSummaryDashboardScreen> {
  List<SiteModel> _activeSites = [];
  CategoryExpenseSummary _expenseSummary = CategoryExpenseSummary(
    materialTotal: 0.0,
    labourTotal: 0.0,
    vendorTotal: 0.0,
    equipmentTotal: 0.0,
    extraTotal: 0.0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> rawSites = await DatabaseHelper.instance.getSites();

      List<SiteModel> loadedSites = [];
      double totalMaterial = 0.0;
      double totalLabour = 0.0;
      double totalVendor = 0.0;
      double totalEquipment = 0.0;
      double totalExtra = 0.0;

      if (rawSites.isNotEmpty) {
        for (var siteMap in rawSites) {
          String sName = siteMap['name']?.toString() ?? 'Unnamed Site';

          loadedSites.add(
            SiteModel(
              siteName: sName,
              status: "Ongoing",
              budget: 500000.0,
              receivedAmount: 350000.0,
            ),
          );

          try {
            List<Map<String, dynamic>> matExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Material');
            totalMaterial += _calculateSum(matExpenses);

            List<Map<String, dynamic>> labExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Labour');
            totalLabour += _calculateSum(labExpenses);

            List<Map<String, dynamic>> venExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Vendor');
            totalVendor += _calculateSum(venExpenses);

            List<Map<String, dynamic>> eqExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Equipment');
            totalEquipment += _calculateSum(eqExpenses);

            List<Map<String, dynamic>> extExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Extra');
            totalExtra += _calculateSum(extExpenses);
          } catch (_) {
            // Catch error per site if category subcollection doesn't exist yet
          }
        }
      }

      if (loadedSites.isEmpty) {
        loadedSites.add(
          SiteModel(
            siteName: widget.defaultSiteName,
            status: "Main Site - Ongoing",
            budget: 1500000.0,
            receivedAmount: 1050000.0,
          ),
        );
      }

      setState(() {
        _activeSites = loadedSites;
        _expenseSummary = CategoryExpenseSummary(
          materialTotal: totalMaterial > 0 ? totalMaterial : 420000.0,
          labourTotal: totalLabour > 0 ? totalLabour : 250000.0,
          vendorTotal: totalVendor > 0 ? totalVendor : 85000.0,
          equipmentTotal: totalEquipment > 0 ? totalEquipment : 55000.0,
          extraTotal: totalExtra > 0 ? totalExtra : 35000.0,
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateSum(List<Map<String, dynamic>> expenses) {
    double sum = 0.0;
    for (var item in expenses) {
      if (item.containsKey('amount')) {
        sum += double.tryParse(item['amount'].toString()) ?? 0.0;
      }
    }
    return sum;
  }

  double get _totalBudget =>
      _activeSites.fold(0.0, (sum, site) => sum + site.budget);

  double get _totalReceived =>
      _activeSites.fold(0.0, (sum, site) => sum + site.receivedAmount);

  double get _totalPending => _totalBudget - _totalReceived;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Maher Contractor",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.defaultSiteName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    widget.clientName.isNotEmpty
                                        ? widget.clientName[0]
                                        : 'M',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Welcome, ${widget.clientName} 👋",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "● ON SCHEDULE",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Project Overview & Health",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.defaultSiteName,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.apartment,
                                  color: Colors.indigo,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Active Sites (${_activeSites.length})",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Chalu Sites",
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ..._activeSites.map(
                          (site) => _buildSiteItem(
                            site.siteName,
                            site.status,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Financial Summary",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFinancialItem(
                              "Total Budget",
                              "₹ ${_formatCurrency(_totalBudget)}",
                              Colors.black,
                            ),
                            _buildFinancialItem(
                              "Jama (Received)",
                              "₹ ${_formatCurrency(_totalReceived)}",
                              Colors.green,
                            ),
                            _buildFinancialItem(
                              "Pending Due",
                              "₹ ${_formatCurrency(_totalPending)}",
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Expense Breakdown",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total: ₹ ${_formatCurrency(_expenseSummary.grandTotal)}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Material",
                          amount:
                              "₹ ${_formatCurrency(_expenseSummary.materialTotal)}",
                          icon: Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Labour",
                          amount:
                              "₹ ${_formatCurrency(_expenseSummary.labourTotal)}",
                          icon: Icons.groups_outlined,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Vendor",
                          amount:
                              "₹ ${_formatCurrency(_expenseSummary.vendorTotal)}",
                          icon: Icons.local_shipping_outlined,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Equipment",
                          amount:
                              "₹ ${_formatCurrency(_expenseSummary.equipmentTotal)}",
                          icon: Icons.construction_outlined,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    title: "Extra / Misc Kharch",
                    amount:
                        "₹ ${_formatCurrency(_expenseSummary.extraTotal)}",
                    icon: Icons.more_horiz_outlined,
                    color: Colors.redAccent,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "View Site Management",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSiteItem(String name, String status, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}