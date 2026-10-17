import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'database_helper.dart';

class SiteModel {
  final String siteName;
  final String status;
  double budget;
  double receivedAmount;

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
  List<Map<String, dynamic>> _allSitesLabours = [];
  CategoryExpenseSummary _expenseSummary = CategoryExpenseSummary(
    materialTotal: 0.0,
    labourTotal: 0.0,
    vendorTotal: 0.0,
    equipmentTotal: 0.0,
    extraTotal: 0.0,
  );
  bool _isLoading = true;

  // Financial Summary States
  double _totalBudget = 0.0;
  double _totalReceived = 0.0;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _fetchDashboardData();
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString('contractor_profile_image');
      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          _profileImage = File(savedPath);
        });
      }

      setState(() {
        _totalBudget = prefs.getDouble('dashboard_total_budget') ?? 0.0;
        _totalReceived = prefs.getDouble('dashboard_total_received') ?? 0.0;
      });
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
    }
  }

  Future<void> _saveFinancialPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('dashboard_total_budget', _totalBudget);
      await prefs.setDouble('dashboard_total_received', _totalReceived);
    } catch (e) {
      debugPrint("Save Financial Prefs Error: $e");
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
      List<Map<String, dynamic>> allLaboursTemp = [];

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
              budget: 0.0,
              receivedAmount: 0.0,
            ),
          );

          try {
            List<Map<String, dynamic>> matExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Material');
            totalMaterial += _calculateSum(matExpenses);

            List<Map<String, dynamic>> labExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Labour');
            totalLabour += _calculateSum(labExpenses);

            // Fetch Labour list and extract phone numbers dynamically
            for (var lab in labExpenses) {
              String desc = lab['desc']?.toString() ?? '';
              String phoneNum = '';
              
              if (desc.contains('Phone:')) {
                try {
                  int startIndex = desc.indexOf('Phone:') + 7;
                  int endIndex = desc.indexOf(' |', startIndex);
                  if (endIndex != -1) {
                    phoneNum = desc.substring(startIndex, endIndex).trim();
                  }
                } catch (_) {}
              }

              allLaboursTemp.add({
                'siteName': sName,
                'name': lab['title'] ?? 'Worker',
                'phone': phoneNum,
                'status': desc,
              });
            }

            List<Map<String, dynamic>> venExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Vendor');
            totalVendor += _calculateSum(venExpenses);

            List<Map<String, dynamic>> eqExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Equipment');
            totalEquipment += _calculateSum(eqExpenses);

            List<Map<String, dynamic>> extExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Extra');
            totalExtra += _calculateSum(extExpenses);

            List<Map<String, dynamic>> miscExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Misc');
            totalExtra += _calculateSum(miscExpenses);

            List<Map<String, dynamic>> otherExpenses = await DatabaseHelper.instance.getExpenses(sName, 'Other');
            totalExtra += _calculateSum(otherExpenses);
             
            List<Map<String, dynamic>> otherExpenseCat = await DatabaseHelper.instance.getExpenses(sName, 'Other Expense');
            totalExtra += _calculateSum(otherExpenseCat);

          } catch (_) {}
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
        _allSitesLabours = allLaboursTemp;
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

  //Direct Phone Call Function
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.trim(),
    );
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch $phoneNumber");
    }
  }

  void _showEditFinancialDialog() {
    TextEditingController budgetController =
        TextEditingController(text: _totalBudget > 0 ? _totalBudget.toStringAsFixed(0) : '');
    TextEditingController receivedController =
        TextEditingController(text: _totalReceived > 0 ? _totalReceived.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Edit Financial Summary",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Total Budget (₹)",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: receivedController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Jama / Total Received (₹)",
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              setState(() {
                _totalBudget = double.tryParse(budgetController.text) ?? 0.0;
                _totalReceived = double.tryParse(receivedController.text) ?? 0.0;
              });
              _saveFinancialPrefs();
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = _expenseSummary.grandTotal;
    
    // Automatic Calculation: Pending Due from Client = Total Budget - Total Received (Jama)
    double pendingFromClient = _totalBudget - _totalReceived;
    if (pendingFromClient < 0) pendingFromClient = 0;

    // Automatic Calculation: Remaining Budget = Total Budget - Total Expense (Kharch)
    double remainingBudget = _totalBudget - grandTotal;

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

                  // 2. FINANCIAL SUMMARY CARD (WITH AUTOMATIC PENDING CALCULATION)
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Financial Summary",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF38BDF8), size: 18),
                              onPressed: _showEditFinancialDialog,
                              tooltip: "Edit Budget & Jama",
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFinancialItem("Total Budget", "₹ ${_formatCurrency(_totalBudget)}", const Color(0xFF38BDF8)),
                            _buildFinancialItem("Jama (Received)", "₹ ${_formatCurrency(_totalReceived)}", const Color(0xFF34D399)),
                            _buildFinancialItem("Pending Due", "₹ ${_formatCurrency(pendingFromClient)}", const Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Expense (Kharch)",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            Text(
                              "₹ ${_formatCurrency(grandTotal)}",
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Remaining Budget Shillak",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            Text(
                              "₹ ${_formatCurrency(remainingBudget < 0 ? 0 : remainingBudget)}",
                              style: TextStyle(
                                color: remainingBudget < 0 ? Colors.redAccent : const Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. ALL SITES LABOUR & CALL SECTION
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.engineering_rounded,
                                  color: Color(0xFF34D399),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "All Sites Labour & Call",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_allSitesLabours.length} Workers",
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
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
                          height: 180,
                          child: _allSitesLabours.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Konthichi labour mahiti uplabdh nahiye.",
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _allSitesLabours.length,
                                  itemBuilder: (context, index) {
                                    final worker = _allSitesLabours[index];
                                    String name = worker['name'];
                                    String siteName = worker['siteName'];
                                    String phone = worker['phone'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Color(0xFF334155),
                                                child: Icon(Icons.person, size: 14, color: Color(0xFF38BDF8)),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 10, color: Color(0xFF38BDF8)),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        siteName,
                                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF34D399), size: 20),
                                            onPressed: () {
                                              if (phone.isNotEmpty) {
                                                _makePhoneCall(phone);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Mobile number not added for this worker")),
                                                );
                                              }
                                            },
                                            tooltip: "Call $name",
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

                  // 4. ACTIVE SITES SECTION
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
                          height: 130,
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

                  // 5. EXPENSE BREAKDOWN COLUMN CHART
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

                  // 6. VIEW SITE MANAGEMENT BUTTON
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

  String _formatCurrency(double amount) {
    String str = amount.toInt().toString();
    if (str.length <= 3) return str;
    
    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);
    
    otherNumbers = otherNumbers.replaceAllMapped(
      RegExp(r'(\d{1,2})(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return '$otherNumbers,$lastThree';
  }
}