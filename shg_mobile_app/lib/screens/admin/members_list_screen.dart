import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  String searchQuery = "";
  bool _authLookupStarted = false;
  bool _authLookupFailed = false;

  Future<void> _loadAdminShgId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _authLookupFailed = true);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final shgId = userData?['shgId'] as String?;

      if (!userDoc.exists || shgId == null || shgId.isEmpty) {
        if (mounted) setState(() => _authLookupFailed = true);
        return;
      }

      if (!mounted) return;
      context.read<AuthProvider>().setAuthData(
        shgId: shgId,
        userRole: userData?['role'] as String? ?? 'admin',
        userName: userData?['name'] as String? ?? 'Admin',
      );
    } catch (error) {
      debugPrint('Failed to load admin SHG ID: $error');
      if (mounted) setState(() => _authLookupFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final shgId = authProvider.shgId;

          if (shgId == null) {
            if (!_authLookupStarted) {
              _authLookupStarted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadAdminShgId();
              });
            }

            if (_authLookupFailed) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load your SHG. Check that your admin user '
                        'document has a valid shgId.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _authLookupFailed = false;
                            _authLookupStarted = false;
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search members...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ShgGroups')
                      .doc(shgId)
                      .collection('members')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final allMembers = docs
                        .map(
                          (d) => {
                            'id': d.id,
                            'shgId': shgId,
                            ...d.data() as Map<String, dynamic>,
                          },
                        )
                        .toList();

                    List<Map<String, dynamic>> filteredMembers = allMembers
                        .where((m) {
                          String name = m['name'] ?? m['firstName'] ?? '';
                          return name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                        })
                        .toList();

                    if (filteredMembers.isEmpty) {
                      return const Center(child: Text("No members found."));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        return _buildMemberCard(filteredMembers[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    bool isPending = member['status'] == 'PENDING';
    String name = member['name'] ?? member['firstName'] ?? 'Unknown';
    String joinedDate = member['joinedDate'] ?? 'Unknown';
    double trustScore = (member['trustScore'] ?? 0).toDouble();
    double savings = (member['savings'] ?? 0).toDouble();
    bool hasActiveLoan = member['hasActiveLoan'] ?? false;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isPending ? Colors.orange.shade200 : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  foregroundColor: Colors.teal.shade800,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPending)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Pending",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Joined: $joinedDate",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPending)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Trust Score",
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                      Text(
                        trustScore.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!isPending) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        "Savings",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        "₹$savings",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        "Active Loan",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        hasActiveLoan ? "Yes" : "No",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('ShgGroups')
                            .doc(member['shgId'])
                            .collection('members')
                            .doc(member['id'])
                            .update({'status': 'REJECTED'});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('ShgGroups')
                            .doc(member['shgId'])
                            .collection('members')
                            .doc(member['id'])
                            .update({'status': 'APPROVED'});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
