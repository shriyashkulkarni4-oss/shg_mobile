import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool isSaving = false;

  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final occupationController = TextEditingController();
  final incomeController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    occupationController.dispose();
    incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shgId = context.watch<AuthProvider>().shgId;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (shgId == null || uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('members')
          .doc(uid)
          .snapshots(),
      builder: (context, memberSnap) {
        final memberData = memberSnap.data?.data() as Map<String, dynamic>? ?? {};

        // Populate controllers only when not editing (to not override user input)
        if (!isEditing) {
          phoneController.text = memberData['phoneNumber'] ?? memberData['phone'] ?? '';
          emailController.text = memberData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
          addressController.text = memberData['address'] ?? '';
          occupationController.text = memberData['occupation'] ?? '';
          incomeController.text = (memberData['annualIncome'] ?? '').toString();
        }

        final String name = memberData['name'] ?? memberData['firstName'] ?? 'Member';
        final double trustScore = (memberData['trustScore'] ?? 0).toDouble();
        final String memberSince = memberData['memberSince'] ?? memberData['joinedDate'] ?? 'Unknown';

        // Financial summary streams
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Personal"),
                  Tab(text: "Financial"),
                  Tab(text: "Settings"),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildProfileHeader(name, trustScore, memberSince, shgId),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPersonalInfoTab(name, uid, shgId),
                      _buildFinancialSummaryTab(shgId, uid),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(String name, double trustScore, String memberSince, String shgId) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF0D9488),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildBadge("Active Member", Colors.teal),
                    _buildBadge("Trust: ${trustScore.toInt()}/100", Colors.purple),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Member since $memberSince",
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color.shade800, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPersonalInfoTab(String name, String uid, String shgId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Personal Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              isSaving
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: Icon(isEditing ? Icons.save : Icons.edit,
                          color: const Color(0xFF0D9488)),
                      onPressed: () async {
                        if (isEditing) {
                          setState(() => isSaving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('ShgGroups')
                                .doc(shgId)
                                .collection('members')
                                .doc(uid)
                                .update({
                              'phoneNumber': phoneController.text.trim(),
                              'email': emailController.text.trim(),
                              'address': addressController.text.trim(),
                              'occupation': occupationController.text.trim(),
                              'annualIncome': incomeController.text.trim(),
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Profile saved!'),
                                    backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e')),
                              );
                            }
                          }
                          if (mounted) setState(() => isSaving = false);
                        }
                        setState(() => isEditing = !isEditing);
                      },
                    ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Full Name", name, false),
          _buildTextField("Phone Number", "", isEditing, controller: phoneController),
          _buildTextField("Email", "", isEditing, controller: emailController),
          _buildTextField("Address", "", isEditing, controller: addressController),
          _buildTextField("Occupation", "", isEditing, controller: occupationController),
          _buildTextField("Annual Income (₹)", "", isEditing, controller: incomeController),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Tap the save icon above to save changes",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, bool enabled,
      {TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller ?? TextEditingController(text: value),
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryTab(String shgId, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('loans')
          .where('memberId', isEqualTo: uid)
          .snapshots(),
      builder: (context, loanSnap) {
        int activeLoans = 0;
        double outstandingBalance = 0;
        int totalLoans = 0;
        int completedLoans = 0;

        for (final doc in loanSnap.data?.docs ?? []) {
          final d = doc.data() as Map<String, dynamic>;
          totalLoans++;
          if (d['status'] == 'APPROVED') {
            activeLoans++;
            outstandingBalance +=
                (d['remainingAmount'] ?? d['remaining'] ?? d['amount'] ?? 0).toDouble();
          }
          if (d['status'] == 'COMPLETED') completedLoans++;
        }

        // Contributions from monthly rounds
        return FutureBuilder<double>(
          future: _fetchTotalContributed(shgId, uid),
          builder: (context, contribSnap) {
            final double totalContributed = contribSnap.data ?? 0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryCard("Savings Overview", {
                    "Total Contributed": "₹${totalContributed.toStringAsFixed(0)}",
                    "Interest Rate": "12% p.a.",
                  }),
                  const SizedBox(height: 16),
                  _buildSummaryCard("Loan Information", {
                    "Active Loans": "$activeLoans",
                    "Outstanding Balance": "₹${outstandingBalance.toStringAsFixed(0)}",
                    "Total Loans Applied": "$totalLoans",
                    "Loans Completed": "$completedLoans",
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<double> _fetchTotalContributed(String shgId, String uid) async {
    double total = 0;
    final roundsSnap = await FirebaseFirestore.instance
        .collection('ShgGroups')
        .doc(shgId)
        .collection('monthlyRounds')
        .get();
    for (final rd in roundsSnap.docs) {
      final c = await FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('monthlyRounds')
          .doc(rd.id)
          .collection('contributions')
          .doc(uid)
          .get();
      if (c.exists) {
        total += (c.data()?['amountPaid'] ?? 0).toDouble();
      }
    }
    return total;
  }

  Widget _buildSummaryCard(String title, Map<String, String> data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(color: Colors.black54)),
                      Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("Notification Preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text("Payment Reminders"),
          subtitle: const Text("Get notified before payment due dates"),
          activeColor: const Color(0xFF0D9488),
          value: true,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text("Meeting Reminders"),
          subtitle: const Text("Get notified about upcoming meetings"),
          activeColor: const Color(0xFF0D9488),
          value: true,
          onChanged: (val) {},
        ),
        const Divider(),
        const Text("Account Security",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text("Change Password"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Sign Out"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) context.read<AuthProvider>().clear();
          },
        ),
      ],
    );
  }
}
