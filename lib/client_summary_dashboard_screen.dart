import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    this.defaultSiteName = "Mahesh Dashboard & Workspaces",
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

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
    _fetchDashboardData();
  }

  Future<void> _loadSavedProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString('contractor_profile_image');
      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          _profileImage = File(savedPath);
        });
      }
    } catch (e) {
      debugPrint("Load Image Error: $e");
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      File selectedImage = File(pickedFile.path);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('contractor_profile_image', selectedImage.path);
      } catch (e) {
        debugPrint("Save Image Error: $e");
      }

      setState(() {
        _profileImage = selectedImage;
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

          // 1. Database madhun site chi received/paid amount fetch karne
          double siteReceived = double.tryParse(
            (siteMap['receivedAmount'] ?? siteMap['received_amount'] ?? 0.0).toString(),
          ) ?? 0.0;

          double siteTotalExpense = 0.0;

          try {
            List<Map<String, dynamic>> matExpenses = await DatabaseHelper.instance.getExpenses(sName, 'material');
            double matSum = _calculateSum(matExpenses);
            totalMaterial += matSum;
            siteTotalExpense += matSum;

            List<Map<String, dynamic>> labExpenses = await DatabaseHelper.instance.getExpenses(sName, 'labour');
            double labSum = _calculateSum(labExpenses);
            totalLabour += labSum;
            siteTotalExpense += labSum;

            List<Map<String, dynamic>> venExpenses = await DatabaseHelper.instance.getExpenses(sName, 'vendor');
            double venSum = _calculateSum(venExpenses);
            totalVendor += venSum;
            siteTotalExpense += venSum;

            List<Map<String, dynamic>> eqExpenses = await DatabaseHelper.instance.getExpenses(sName, 'equipment');
            double eqSum = _calculateSum(eqExpenses);
            totalEquipment += eqSum;
            siteTotalExpense += eqSum;

            List<Map<String, dynamic>> extExpenses = await DatabaseHelper.instance.getExpenses(sName, 'extra');
            double extSum = _calculateSum(extExpenses);
            totalExtra += extSum;
            siteTotalExpense += extSum;

            List<Map<String, dynamic>> miscExpenses = await DatabaseHelper.instance.getExpenses(sName, 'misc');
            double miscSum = _calculateSum(miscExpenses);
            totalExtra += miscSum;
            siteTotalExpense += miscSum;

            List<Map<String, dynamic>> otherExpenses = await DatabaseHelper.instance.getExpenses(sName, 'other');
            double otherSum = _calculateSum(otherExpenses);
            totalExtra += otherSum;
            siteTotalExpense += otherSum;
          } catch (_) {}

          // 2. Pratyek sitecha dynamic total expense ani received amount addd karne
          loadedSites.add(
            SiteModel(
              siteName: sName,
              status: "Ongoing",
              budget: siteTotalExpense, 
              receivedAmount: siteReceived, 
            ),
          );
        }
      }

      if (loadedSites.isEmpty) {
        loadedSites.add(
          SiteModel(
            siteName: widget.defaultSiteName,
            status: "Main Site - Ongoing",
            budget: 0.0,
            receivedAmount: 0.0,
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
      final amount = item['amount'] ?? item['cost'] ?? 0.0;
      sum += double.tryParse(amount.toString()) ?? 0.0;
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

    double maxAmount = [
      _expenseSummary.materialTotal,
      _expenseSummary.labourTotal,
      _expenseSummary.vendorTotal,
      _expenseSummary.equipmentTotal,
      _expenseSummary.extraTotal,
    ].reduce((curr, next) => curr > next ? curr : next);

    if (maxAmount <= 0) maxAmount = 100000.0;

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
              "My projects",
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WELCOME BANNER WITH PERMANENT DP
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
                          children: [
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
                              Icons.business_center_rounded,
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
                                "Sites",
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
                          height: 140,
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
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF34D399),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                site.siteName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Total Expense', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                '₹ ${_formatCurrency(site.budget)}',
                                                style: const TextStyle(
                                                  color: Color(0xFF38BDF8),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. EXPENSE BREAKDOWN COLUMN CHART
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Expense Breakdown Chart",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Total: ₹ ${_formatCurrency(grandTotal)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left Y-Axis Labels
                            SizedBox(
                              height: 180,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_formatShortCurrency(maxAmount), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  Text(_formatShortCurrency(maxAmount * 0.75), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  Text(_formatShortCurrency(maxAmount * 0.5), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  Text(_formatShortCurrency(maxAmount * 0.25), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  const Text("0", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Vertical Bars Container with Grid Lines
                            Expanded(
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(5, (_) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1)),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 180,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildVerticalBar("Material", _expenseSummary.materialTotal, maxAmount, const Color(0xFF38BDF8)),
                                        _buildVerticalBar("Labour", _expenseSummary.labourTotal, maxAmount, const Color(0xFFF59E0B)),
                                        _buildVerticalBar("Vendor", _expenseSummary.vendorTotal, maxAmount, const Color(0xFFA855F7)),
                                        _buildVerticalBar("Equip.", _expenseSummary.equipmentTotal, maxAmount, const Color(0xFF14B8A6)),
                                        _buildVerticalBar("Extra", _expenseSummary.extraTotal, maxAmount, const Color(0xFFEF4444)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. VIEW SITE MANAGEMENT BUTTON
                  SizedBox(
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
                        ).then((_) {
                          _fetchDashboardData();
                        });
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildVerticalBar(String label, double amount, double maxAmount, Color color) {
    double barHeight = (amount / maxAmount) * 135.0;
    if (barHeight < 12.0) barHeight = 12.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatShortCurrency(amount),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  String _formatShortCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
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