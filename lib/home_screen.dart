import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'login_screen.dart';
import 'site_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _sites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    setState(() => _isLoading = true);
    final sites = await DatabaseHelper.instance.getSites();
    setState(() {
      _sites = sites;
      _isLoading = false;
    });
  }

  void _showAddSiteDialog() {
    final TextEditingController siteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Site', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: siteController,
          decoration: InputDecoration(
            hintText: 'Site Name',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (siteController.text.trim().isNotEmpty) {
                await DatabaseHelper.instance.insertSite(siteController.text.trim());

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }

                if (mounted) {
                  _loadSites();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 3),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out from Site Management?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: const Color(0xFFF8FAFC),
                            foregroundColor: const Color(0xFF475569),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.red.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await FirebaseAuth.instance.signOut();

                            if (!mounted) return;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Site Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _showLogoutDialog,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No sites added yet!', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        onPressed: _showAddSiteDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Site'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sites.length,
                  itemBuilder: (context, index) {
                    final site = _sites[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.apartment, color: Colors.white),
                        ),
                        title: Text(
                          site['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text('Tap to view expenses', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SiteDetailScreen(siteName: site['name']),
                            ),
                          ).then((_) {
                            _loadSites();
                          });
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        onPressed: _showAddSiteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}