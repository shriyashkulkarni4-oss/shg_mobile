import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _agreeToTerms = false;
  String? _selectedGroupId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _shgGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('ShgGroups').get();
      setState(() {
        _shgGroups = snap.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['groupName'] ?? 'Unknown Group',
        }).toList();
      });
    } catch (e) {
      debugPrint("Failed to load SHGs: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a SHG group')),
      );
      return;
    }
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final user = userCred.user;
      if (user == null) throw Exception("User is null");
      
      final groupId = _selectedGroupId!;
      
      // Save global user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': _emailController.text.trim(),
        'phoneNumber': '+91${_phoneController.text.trim()}',
        'phoneVerified': false,
        'role': 'member',
        'shgId': groupId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Save member INSIDE SHG
      await FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(groupId)
          .collection('members')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': '+91${_phoneController.text.trim()}',
        'role': 'member',
        'trustScore': 50,
        'status': 'ACTIVE',
        'shgId': groupId,
        'address': _addressController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please verify your phone number.')),
      );
      
      // Navigate to login
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/login');
      });
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              Color(0xFFF0FDF4), // teal-50
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFFAF5FF), // purple-50
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
                  _buildSignupCard(),
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
            color: Color(0xFF0D9488),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group_add, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          "Join SHG Portal",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          "Create your account to get started",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSignupCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Member Registration", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Fill in your details to join a Self Help Group", style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 24),
              
              const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTextField(_nameController, "Full Name *", Icons.person_outline, validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email Address *", Icons.mail_outline, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number *", Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return "Enter a valid 10-digit mobile number";
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_occupationController, "Occupation", Icons.work_outline),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Address", Icons.location_on_outlined),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text("Group Selection", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select SHG Group',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGroupId,
                items: _shgGroups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group['id'],
                    child: Text(group['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedGroupId = value),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text("Security", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, "Password *", Icons.lock_outline, obscureText: true, validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null),
              const SizedBox(height: 16),
              _buildTextField(_confirmPasswordController, "Confirm Password *", Icons.lock_outline, obscureText: true, validator: (v) => v != _passwordController.text ? "Passwords do not match" : null),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                    activeColor: const Color(0xFF0D9488),
                  ),
                  const Expanded(
                    child: Text(
                      "I agree to the terms and conditions of the SHG and understand that my application will be reviewed.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Create Account"),
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text("Login here", style: TextStyle(color: Color(0xFF0D9488))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
