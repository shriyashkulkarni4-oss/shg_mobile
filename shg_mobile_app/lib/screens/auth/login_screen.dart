import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _memberEmailController = TextEditingController();
  final _memberPasswordController = TextEditingController();
  
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _memberEmailController.dispose();
    _memberPasswordController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _findMemberShg(String uid) async {
    final shgSnap = await FirebaseFirestore.instance.collection('ShgGroups').get();
    
    for (var shg in shgSnap.docs) {
      final memberRef = FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shg.id)
          .collection('members')
          .doc(uid);
          
      final memberSnap = await memberRef.get();
      if (memberSnap.exists) {
        return {
          'shgId': shg.id,
          'role': memberSnap.data()?['role'],
        };
      }
    }
    return null;
  }

  Future<void> _handleLogin({required bool isAdmin}) async {
    final email = isAdmin ? _adminEmailController.text.trim() : _memberEmailController.text.trim();
    final password = isAdmin ? _adminPasswordController.text.trim() : _memberPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCred.user;
      if (user == null) throw Exception("User is null");

      if (isAdmin) {
        final adminDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!adminDoc.exists) {
          throw Exception("Admin profile not found");
        }
        
        if (!mounted) return;
        context.go('/admin');
      } else {
        final membership = await _findMemberShg(user.uid);
        if (membership == null) {
          throw Exception("You are not registered in any SHG");
        }
        
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final bool phoneVerified = userDoc.data()?['phoneVerified'] ?? false;
        final String phone = userDoc.data()?['phoneNumber'] ?? '';
        
        if (!mounted) return;
        
        final String shgId = membership['shgId'];
        final String role = membership['role'] ?? 'Member';
        final String name = userDoc.data()?['name'] ?? 'User';
        
        context.read<AuthProvider>().setAuthData(
          shgId: shgId,
          userRole: role,
          userName: name,
        );

        if (!phoneVerified) {
          context.go('/verify-phone', extra: {'uid': user.uid, 'phone': phone});
        } else {
          context.go('/member');
        }
      }
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // teal-50 approx
              Color(0xFFEFF6FF), // blue-50 approx
              Color(0xFFFAF5FF), // purple-50 approx
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildLoginCard(),
                  const SizedBox(height: 24),
                  const Text(
                    "Empowering communities through financial inclusion",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF0D9488), // teal-600
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.group,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "SHG Portal",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Self Help Group Management System",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Login to Your Account",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose your account type to continue",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0D9488),
              unselectedLabelColor: Colors.black54,
              indicatorColor: const Color(0xFF0D9488),
              tabs: const [
                Tab(text: "Member"),
                Tab(text: "Admin"),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMemberLoginForm(),
                  _buildAdminLoginForm(),
                ],
              ),
            ),
              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: const Text(
                    "Sign up here",
                    style: TextStyle(color: Color(0xFF0D9488)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMemberLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _memberEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _memberPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleLogin(isAdmin: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A), // slate-900 approx
              foregroundColor: Colors.white,
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Login as Member"),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _adminEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleLogin(isAdmin: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A), // slate-900 approx
              foregroundColor: Colors.white,
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Login as Admin"),
          ),
        ),
      ],
    );
  }
}
