import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String siteName;
  final String categoryTitle;

  const CategoryDetailScreen({super.key, required this.siteName, required this.categoryTitle});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = true;

  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  String _selectedYear = DateTime.now().year.toString();
  List<String> _yearsList = [DateTime.now().year.toString()];

  final List<Map<String, String>> _monthsList = [
    {'val': '01', 'name': 'January'},
    {'val': '02', 'name': 'February'},
    {'val': '03', 'name': 'March'},
    {'val': '04', 'name': 'April'},
    {'val': '05', 'name': 'May'},
    {'val': '06', 'name': 'June'},
    {'val': '07', 'name': 'July'},
    {'val': '08', 'name': 'August'},
    {'val': '09', 'name': 'September'},
    {'val': '10', 'name': 'October'},
    {'val': '11', 'name': 'November'},
    {'val': '12', 'name': 'December'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryTitle.toLowerCase().contains('labour')) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _loadExpenses();
    _searchController.addListener(_filterSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getExpenses(widget.siteName, widget.categoryTitle);
    
    Set<String> yearsSet = {};
    for (var exp in data) {
      String dateStr = exp['date']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        String year = dateStr.substring(0, 4);
        if (int.tryParse(year) != null) {
          yearsSet.add(year);
        }
      }
    }
    yearsSet.add(DateTime.now().year.toString());
    List<String> sortedYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _expenses = data;
      _filteredExpenses = data;
      _yearsList = sortedYears;
      if (!_yearsList.contains(_selectedYear) && _yearsList.isNotEmpty) {
        _selectedYear = _yearsList.first;
      }
      _isLoading = false;
    });
  }

  void _filterSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExpenses = _expenses.where((exp) {
        final title = exp['title']?.toString().toLowerCase() ?? '';
        final desc = exp['desc']?.toString().toLowerCase() ?? '';
        final date = exp['date']?.toString().toLowerCase() ?? '';
        final unit = exp['unit']?.toString().toLowerCase() ?? '';
        return title.contains(query) || desc.contains(query) || date.contains(query) || unit.contains(query);
      }).toList();
    });
  }

  final List<String> _materialOptions = ['Sand', 'Agg', 'Steel', 'Cement', 'Bitumin'];
  final List<String> _equipmentOptions = ['J.C.B', 'Poclain', 'Tractor', 'Tanker', 'Roller', 'Mixer Machine'];
  final List<String> _vendorStatusOptions = ['Paid', 'Pending'];
  final List<String> _labourStatusOptions = ['Present (Full Day)', 'Half Day', 'Absent'];
  final List<String> _labourPaymentStatusOptions = ['Paid', 'Pending'];
  final List<String> _otherCategoryOptions = ['Tea / Nashta', 'Transport / Travel', 'Stationery', 'Miscellaneous'];
  final List<String> _paymentModeOptions = ['Cash', 'Online / UPI'];

  String? _selectedSubMaterial;
  String? _selectedSubEquipment;
  String? _selectedVendorStatus;
  String? _selectedLabourStatus;
  String? _selectedLabourPaymentStatus;
  String? _selectedOtherCategory;
  String? _selectedPaymentMode;

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var exp in _filteredExpenses) {
      total += double.tryParse(exp['amount'].toString()) ?? 0.0;
    }
    return total;
  }

  Future<void> _deleteExpense(dynamic id) async {
    await DatabaseHelper.instance.deleteExpenseById(widget.siteName, widget.categoryTitle, id);
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted successfully!'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Map<String, Map<String, dynamic>> _getMonthlyLabourSummary() {
    Map<String, Map<String, dynamic>> summary = {};

    var monthFiltered = _expenses.where((exp) {
      String dateStr = exp['date']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        DateTime? parsedDate = DateTime.tryParse(dateStr.split(' ')[0]);
        if (parsedDate != null) {
          String yearStr = parsedDate.year.toString();
          String monthStr = parsedDate.month.toString().padLeft(2, '0');
          return yearStr == _selectedYear && monthStr == _selectedMonth;
        } else if (dateStr.length >= 7) {
          String yearPart = dateStr.substring(0, 4);
          String monthPart = dateStr.substring(5, 7);
          return yearPart == _selectedYear && monthPart == _selectedMonth;
        }
      }
      return false;
    }).toList();

    for (var entry in monthFiltered) {
      String workerName = (entry['title'] != null && entry['title'].toString().trim().isNotEmpty)
          ? entry['title'].toString()
          : 'Labour';
      String desc = entry['desc']?.toString() ?? '';
      double amount = double.tryParse(entry['amount'].toString()) ?? 0.0;

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

      if (!summary.containsKey(workerName)) {
        summary[workerName] = {
          'name': workerName,
          'phone': phoneNum,
          'fullDays': 0,
          'halfDays': 0,
          'absent': 0,
          'totalPaid': 0.0,
          'totalPending': 0.0,
        };
      } else if (summary[workerName]!['phone'].toString().isEmpty && phoneNum.isNotEmpty) {
        summary[workerName]!['phone'] = phoneNum;
      }

      if (desc.contains('Half Day')) {
        summary[workerName]!['halfDays'] = (summary[workerName]!['halfDays'] as int) + 1;
      } else if (desc.contains('Absent')) {
        summary[workerName]!['absent'] = (summary[workerName]!['absent'] as int) + 1;
      } else {
        summary[workerName]!['fullDays'] = (summary[workerName]!['fullDays'] as int) + 1;
      }

      if (desc.contains('Pay: Paid') || desc.contains('Paid')) {
        summary[workerName]!['totalPaid'] = (summary[workerName]!['totalPaid'] as double) + amount;
      } else {
        summary[workerName]!['totalPending'] = (summary[workerName]!['totalPending'] as double) + amount;
      }
    }

    return summary;
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    double totalAmount = _calculateTotalAmount();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${widget.categoryTitle} Expense Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Site Name: ${widget.siteName}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Category: ${widget.categoryTitle}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Title / Item', 'Unit/Qty', 'Details / Note', 'Date', 'Amount (Rs)'],
                data: _filteredExpenses.map((exp) {
                  return [
                    exp['title'].toString(),
                    exp['unit']?.toString() ?? '-',
                    exp['desc'].toString(),
                    exp['date'].toString(),
                    exp['amount'].toString(),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total Amount: Rs $totalAmount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '${widget.siteName}_${widget.categoryTitle}_report.pdf');
  }

  void _showAddOrEditDialog({Map<String, dynamic>? existingExpense}) {
    bool isEditing = existingExpense != null;
    String cat = widget.categoryTitle.toLowerCase();

    if (cat.contains('material')) {
      _selectedSubMaterial = isEditing ? existingExpense['title'] : _materialOptions.first;
    } else if (cat.contains('equipment')) {
      _selectedSubEquipment = isEditing ? existingExpense['title'] : _equipmentOptions.first;
    } else if (cat.contains('vendor')) {
      _selectedVendorStatus = _vendorStatusOptions.first;
    } else if (cat.contains('labour')) {
      _selectedLabourStatus = _labourStatusOptions.first;
      _selectedLabourPaymentStatus = _labourPaymentStatusOptions.first;
      
      if (isEditing && existingExpense['desc'] != null) {
        String descStr = existingExpense['desc'].toString();
        if (descStr.contains('Half Day')) {
          _selectedLabourStatus = 'Half Day';
        } else if (descStr.contains('Absent')) {
          _selectedLabourStatus = 'Absent';
        } else {
          _selectedLabourStatus = 'Present (Full Day)';
        }

        if (descStr.contains('Paid')) {
          _selectedLabourPaymentStatus = 'Paid';
        } else {
          _selectedLabourPaymentStatus = 'Pending';
        }
      }
    } else if (cat.contains('other') || cat.contains('expense')) {
      _selectedOtherCategory = _otherCategoryOptions.first;
      _selectedPaymentMode = _paymentModeOptions.first;
    }

    final TextEditingController titleController = TextEditingController(text: isEditing ? existingExpense['title']?.toString() : '');
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController unitController = TextEditingController(text: isEditing ? existingExpense['unit']?.toString() : '');
    final TextEditingController amountController = TextEditingController(text: isEditing ? existingExpense['amount']?.toString() : '');
    final TextEditingController descController = TextEditingController();

    if (isEditing && existingExpense['desc'] != null && cat.contains('labour')) {
      String rawDesc = existingExpense['desc'].toString();
      if (rawDesc.contains('Phone:')) {
        try {
          int startIndex = rawDesc.indexOf('Phone:') + 7;
          int endIndex = rawDesc.indexOf(' |', startIndex);
          if (endIndex != -1) {
            phoneController.text = rawDesc.substring(startIndex, endIndex).trim();
          }
        } catch (_) {}
      }
    }

    if (isEditing && existingExpense['desc'] != null) {
      String rawDesc = existingExpense['desc'].toString();
      if (cat.contains('labour')) {
        var parts = rawDesc.split(' - ');
        if (parts.length > 1) {
          descController.text = parts[1];
        } else {
          descController.text = '';
        }
      } else {
        descController.text = rawDesc;
      }
    }

    DateTime selectedDate = isEditing && existingExpense['date'] != null
        ? (DateTime.tryParse(existingExpense['date'].toString().split(' ')[0]) ?? DateTime.now())
        : DateTime.now();

    TimeOfDay selectedTime = TimeOfDay.now();
    if (isEditing && existingExpense['date'] != null) {
      try {
        var parts = existingExpense['date'].toString().split(' ');
        if (parts.length > 1) {
          var timeParts = parts[1].split(':');
          selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? DateTime.now().hour,
            minute: int.tryParse(timeParts[1]) ?? DateTime.now().minute,
          );
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEditing ? '${widget.categoryTitle} Edit' : '${widget.categoryTitle} Add New Expense',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat.contains('material')) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubMaterial,
                      decoration: InputDecoration(
                        labelText: 'Select Material',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _materialOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedSubMaterial = val),
                    ),
                    const SizedBox(height: 14),
                  ] else if (cat.contains('equipment')) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubEquipment,
                      decoration: InputDecoration(
                        labelText: 'Select Equipment',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _equipmentOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedSubEquipment = val),
                    ),
                    const SizedBox(height: 14),
                  ] else if (cat.contains('labour')) ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Worker Name',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number (Optional)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLabourStatus,
                      decoration: InputDecoration(
                        labelText: 'Attendance / Shift Status',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _labourStatusOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedLabourStatus = val),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLabourPaymentStatus,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _labourPaymentStatusOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedLabourPaymentStatus = val),
                    ),
                    const SizedBox(height: 14),
                  ] else if (cat.contains('vendor')) ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Vendor / Trader Name',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVendorStatus,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _vendorStatusOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedVendorStatus = val),
                    ),
                    const SizedBox(height: 14),
                  ] else if (cat.contains('other') || cat.contains('expense')) ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Expense Name (Item Title)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOtherCategory,
                      decoration: InputDecoration(
                        labelText: 'Expense Category',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _otherCategoryOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedOtherCategory = val),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (cat.contains('material')) ...[
                    TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit / Quantity (उदा. Bags, Ton, Nos)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (cat.contains('equipment')) ...[
                    TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit / Usage (उदा. Hrs, Days, Shifts, Trips)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Note / Description (Optional)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Amount (₹)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (cat.contains('other') || cat.contains('expense')) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMode,
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _paymentModeOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedPaymentMode = val),
                    ),
                    const SizedBox(height: 14),
                  ],

                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        dialogSetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text('Date:', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        dialogSetState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text('Time:', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  String expenseTitle = titleController.text.trim();
                  if (expenseTitle.isEmpty) {
                    if (cat.contains('material')) {
                      expenseTitle = _selectedSubMaterial ?? 'Material';
                    } else if (cat.contains('equipment')) {
                      expenseTitle = _selectedSubEquipment ?? 'Equipment';
                    } else if (cat.contains('other') || cat.contains('expense')) {
                      expenseTitle = _selectedOtherCategory ?? 'Other Expense';
                    } else {
                      expenseTitle = widget.categoryTitle;
                    }
                  }

                  if (amountController.text.trim().isNotEmpty) {
                    String userDesc = descController.text.trim();
                    String fullDesc = userDesc;

                    if (cat.contains('labour')) {
                      String phoneNum = phoneController.text.trim();
                      String attendanceStatus = _selectedLabourStatus ?? 'Present (Full Day)';
                      String paymentStatusText = 'Pay: ${_selectedLabourPaymentStatus ?? 'Pending'}';
                      
                      String phonePart = phoneNum.isNotEmpty ? 'Phone: $phoneNum | ' : '';
                      if (userDesc.isNotEmpty) {
                        fullDesc = '$phonePart$attendanceStatus, $paymentStatusText - $userDesc';
                      } else {
                        fullDesc = '$phonePart$attendanceStatus, $paymentStatusText';
                      }
                    }

                    String formattedDateOnly = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    String formattedDateTime = '$formattedDateOnly ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                    String generatedId = DateTime.now().millisecondsSinceEpoch.toString();
                    if (cat.contains('labour')) {
                      String cleanWorkerName = expenseTitle.replaceAll(RegExp(r'\s+'), '_').toLowerCase();
                      generatedId = '${cleanWorkerName}_$formattedDateOnly';
                    }

                    Map<String, dynamic> expenseData = {
                      'id': isEditing ? existingExpense['id'].toString() : generatedId,
                      'title': expenseTitle,
                      'amount': amountController.text.trim(),
                      'unit': (cat.contains('material') || cat.contains('equipment')) ? unitController.text.trim() : '',
                      'desc': fullDesc,
                      'date': formattedDateTime,
                    };

                    if (isEditing) {
                      await DatabaseHelper.instance.updateExpense(widget.siteName, widget.categoryTitle, expenseData);
                    } else {
                      await DatabaseHelper.instance.addExpense(widget.siteName, widget.categoryTitle, expenseData);
                    }

                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                    if (mounted) {
                      _loadExpenses();
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordsView() {
    double totalAmount = _calculateTotalAmount();
    bool isLabourCategory = widget.categoryTitle.toLowerCase().contains('labour');

    return Column(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Entries', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('${_filteredExpenses.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(height: 35, width: 1, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Expense (Total)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('₹ $totalAmount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by entry name or details...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No entries found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = _filteredExpenses[index];
                    final String unitVal = exp['unit']?.toString() ?? '';
                    final String descStr = exp['desc']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showAddOrEditDialog(existingExpense: exp),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isLabourCategory ? Icons.person_rounded : Icons.receipt,
                                    color: const Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (exp['title'] != null && exp['title'].toString().trim().isNotEmpty && exp['title'].toString() != 'null')
                                            ? exp['title'].toString()
                                            : widget.categoryTitle,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 4),
                                      if (!isLabourCategory && unitVal.isNotEmpty) ...[
                                        Text('Unit/Qty: $unitVal', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                      ],
                                      if (!isLabourCategory && descStr.isNotEmpty)
                                        Text(descStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      
                                      Text(
                                        exp['date']?.toString() ?? '',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹ ${exp['amount']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () async {
                                        bool? confirm = await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Delete entry?'),
                                            content: const Text('This entry will be deleted permanently.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          _deleteExpense(exp['id']);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                      ),
                                    ),
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
    );
  }

  Widget _buildMonthlyReportView() {
    var summaryMap = _getMonthlyLabourSummary();
    var workersList = summaryMap.values.toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Month',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _monthsList.map((m) => DropdownMenuItem(value: m['val'], child: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _selectedMonth = val!),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _yearsList.contains(_selectedYear) ? _selectedYear : _yearsList.first,
                  decoration: InputDecoration(
                    labelText: 'Year',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => _selectedYear = val!),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: workersList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.assessment_outlined, size: 48, color: Colors.blue.shade400),
                      ),
                      const SizedBox(height: 16),
                      const Text('No records found for selected month.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: workersList.length,
                  itemBuilder: (context, index) {
                    var worker = workersList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: Color(0xFF3B82F6), width: 5)),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            worker['name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_rounded, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                worker['phone'].toString().isNotEmpty ? worker['phone'] : 'No Phone Added',
                                                style: TextStyle(fontSize: 12, color: worker['phone'].toString().isNotEmpty ? Colors.grey.shade700 : Colors.red.shade300, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text('Due: ₹${worker['totalPending']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.redAccent)),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text('Paid: ₹${worker['totalPaid']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildClassyCountBadge('Full Days', '${worker['fullDays']}', const Color(0xFFEFF6FF), const Color(0xFF3B82F6), Icons.check_circle_outline),
                                  _buildClassyCountBadge('Half Days', '${worker['halfDays']}', const Color(0xFFFEF3C7), const Color(0xFFD97706), Icons.access_time),
                                  _buildClassyCountBadge('Absent', '${worker['absent']}', const Color(0xFFFEE2E2), const Color(0xFFDC2626), Icons.cancel_outlined),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildClassyCountBadge(String label, String count, Color bgColor, Color textColor, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (widget.categoryTitle.toLowerCase().contains('labour')) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text('${widget.siteName} - Labour', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF3B82F6),
            tabs: const [
              Tab(text: 'Daily Records', icon: Icon(Icons.list_alt, size: 18)),
              Tab(text: 'Monthly Report', icon: Icon(Icons.calendar_month, size: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              onPressed: _generateAndSharePdf,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRecordsView(),
            _buildMonthlyReportView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          onPressed: () => _showAddOrEditDialog(),
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B))),
            Text(widget.siteName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            onPressed: _generateAndSharePdf,
          ),
        ],
      ),
      body: _buildRecordsView(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}