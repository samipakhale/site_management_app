import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart';
import 'database_helper.dart';

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
    this.defaultSiteName = "Maher Workspace and Dashboard",
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
  
  // 💡 Profile photo sathi variable
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // 📸 Gallery madhun photo pick karnyachi function
  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
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
          } catch (_) {}
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
          materialTotal: totalMaterial,
          labourTotal: totalLabour,
          vendorTotal: totalVendor,
          equipmentTotal: totalEquipment,
          extraTotal: totalExtra,
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
    double grandTotal = _expenseSummary.grandTotal;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Project details",
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              widget.defaultSiteName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "View Site Management",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF0F172A),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WELCOME BANNER WITH DP PICKER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // 💡 Clickable Profile Photo (WhatsApp DP style)
                                GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFF38BDF8),
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : null,
                                        child: _profileImage == null
                                            ? Text(
                                                widget.clientName.isNotEmpty
                                                    ? widget.clientName[0]
                                                    : 'M',
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 12,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ],
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
                         ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Project Overview",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF94A3B8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.defaultSiteName,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. ACTIVE SITES SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                                  Icons.apartment_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Active Sites (${_activeSites.length})",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
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
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Chalu Sites",
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                        const SizedBox(height: 10),
                        
                        SizedBox(
                          height: 160,
                          child: _activeSites.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Kutlihi active site nahiye.",
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _activeSites.length,
                                  itemBuilder: (context, index) {
                                    final site = _activeSites[index];
                                    return _buildSiteItem(
                                      site.siteName,
                                      site.status,
                                      const Color(0xFF34D399),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. FINANCIAL SUMMARY
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Financial Summary",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
                              Colors.white,
                            ),
                            _buildFinancialItem(
                              "Jama (Received)",
                              "₹ ${_formatCurrency(_totalReceived)}",
                              const Color(0xFF34D399),
                            ),
                            _buildFinancialItem(
                              "Pending Due",
                              "₹ ${_formatCurrency(_totalPending)}",
                              const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _totalBudget > 0
                                ? (_totalReceived / _totalBudget).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. EXPENSE BREAKDOWN & WHITE BACKGROUND BAR CHART SECTION
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Expense Breakdown",
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Total: ₹ ${_formatCurrency(grandTotal)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 16,
                            child: Row(
                              children: [
                                if (grandTotal > 0) ...[
                                  Expanded(
                                    flex: (_expenseSummary.materialTotal * 100 ~/ grandTotal).clamp(1, 100),
                                    child: Container(color: const Color(0xFF0284C7)),
                                  ),
                                  Expanded(
                                    flex: (_expenseSummary.labourTotal * 100 ~/ grandTotal).clamp(1, 100),
                                    child: Container(color: const Color(0xFFD97706)),
                                  ),
                                  Expanded(
                                    flex: (_expenseSummary.vendorTotal * 100 ~/ grandTotal).clamp(1, 100),
                                    child: Container(color: const Color(0xFF7C3AED)),
                                  ),
                                  Expanded(
                                    flex: (_expenseSummary.equipmentTotal * 100 ~/ grandTotal).clamp(1, 100),
                                    child: Container(color: const Color(0xFF0D9488)),
                                  ),
                                  Expanded(
                                    flex: (_expenseSummary.extraTotal * 100 ~/ grandTotal).clamp(1, 100),
                                    child: Container(color: const Color(0xFFDC2626)),
                                  ),
                                ] else
                                  Expanded(
                                    flex: 1,
                                    child: Container(color: Colors.grey.shade300),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWhiteBgChartLegendItem(
                                    "Material",
                                    "₹ ${_formatCurrency(_expenseSummary.materialTotal)}",
                                    const Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildWhiteBgChartLegendItem(
                                    "Labour",
                                    "₹ ${_formatCurrency(_expenseSummary.labourTotal)}",
                                    const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWhiteBgChartLegendItem(
                                    "Vendor",
                                    "₹ ${_formatCurrency(_expenseSummary.vendorTotal)}",
                                    const Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildWhiteBgChartLegendItem(
                                    "Equipment",
                                    "₹ ${_formatCurrency(_expenseSummary.equipmentTotal)}",
                                    const Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildWhiteBgChartLegendItem(
                              "Extra / Misc",
                              "₹ ${_formatCurrency(_expenseSummary.extraTotal)}",
                              const Color(0xFFDC2626),
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Material",
                          amount: "₹ ${_formatCurrency(_expenseSummary.materialTotal)}",
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Labour",
                          amount: "₹ ${_formatCurrency(_expenseSummary.labourTotal)}",
                          icon: Icons.groups_outlined,
                          color: const Color(0xFFF59E0B),
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
                          amount: "₹ ${_formatCurrency(_expenseSummary.vendorTotal)}",
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xFFA855F7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryCard(
                          title: "Equipment",
                          amount: "₹ ${_formatCurrency(_expenseSummary.equipmentTotal)}",
                          icon: Icons.construction_outlined,
                          color: const Color(0xFF14B8A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryCard(
                    title: "Extra / Misc Kharch",
                    amount: "₹ ${_formatCurrency(_expenseSummary.extraTotal)}",
                    icon: Icons.more_horiz_outlined,
                    color: const Color(0xFFEF4444),
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 20),
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
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteBgChartLegendItem(String label, String amount, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
          ),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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