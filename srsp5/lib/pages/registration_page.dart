import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'user_info_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _storyController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _storyFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  final List<String> _countries = const [
    'Kyrgyzstan',
    'Kazakhstan',
    'Russia',
    'Uzbekistan',
    'Tajikistan',
  ];
  String? _selectedCountry;

  bool _hidePass = true;
  bool _hideConfirmPass = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _storyController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _storyFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  void _fieldFocusChange(FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  // ---------- Validators ----------

  String? _validateName(String? value) {
    final nameExp = RegExp(r'^[A-Za-zА-Яа-яЁё ]+$');
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    } else if (!nameExp.hasMatch(value)) {
      return 'Please enter alphabetical characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phoneExp = RegExp(r'^8\d{10}$');
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    } else if (!phoneExp.hasMatch(value)) {
      return 'Phone format: 8XXXXXXXXXX';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final emailExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!emailExp.hasMatch(value)) {
      return 'Invalid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm the password';
    } else if (value != _passController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ---------- Submit ----------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Form is not valid! Please review and correct.');
      return;
    }
    _formKey.currentState!.save();

    final user = User(
      name: _nameController.text.trim(),
      phone: _phoneController.text,
      email: _emailController.text.trim(),
      country: _selectedCountry ?? '',
      story: _storyController.text.trim(),
    );

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: user.email,
            password: _passController.text,
          );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({...user.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    } on FirebaseAuthException catch (e) {
      _showMessage(_authErrorMessage(e));
      return;
    } catch (e) {
      _showMessage('Failed to save data: $e');
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', user.name);
    await prefs.setString('phone', user.phone);
    await prefs.setString('email', user.email);
    await prefs.setString('country', user.country);
    await prefs.setString('story', user.story);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserInfoPage(user: user)),
    );
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return e.message ?? 'Registration failed';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Form'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _fieldFocusChange(_nameFocus, _phoneFocus),
              validator: _validateName,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'What do people call you?',
                prefixIcon: const Icon(Icons.person),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _nameController.clear(),
                ),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(color: Colors.blue, width: 2),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _fieldFocusChange(_phoneFocus, _emailFocus),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: _validatePhone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Where can we reach you?',
                helperText: 'Phone format: 8XXXXXXXXXX',
                prefixIcon: const Icon(Icons.call),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _phoneController.clear(),
                ),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _border(color: Colors.blue, width: 2),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _fieldFocusChange(_emailFocus, _storyFocus),
              validator: _validateEmail,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter an email address',
                icon: const Icon(Icons.mail),
                border: _border(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              decoration: InputDecoration(
                labelText: 'Country',
                icon: const Icon(Icons.map),
                border: _border(),
              ),
              items: _countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCountry = value),
              validator: (value) =>
                  value == null ? 'Please select a country' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _storyController,
              focusNode: _storyFocus,
              maxLines: 3,
              maxLength: 100,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: InputDecoration(
                labelText: 'Life Story',
                hintText: 'Tell us about yourself',
                helperText: 'Keep it short, this is just a demo',
                border: _border(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passController,
              focusNode: _passFocus,
              obscureText: _hidePass,
              maxLength: 16,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  _fieldFocusChange(_passFocus, _confirmPassFocus),
              validator: _validatePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Enter the password',
                icon: const Icon(Icons.security),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
                border: _border(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPassController,
              focusNode: _confirmPassFocus,
              obscureText: _hideConfirmPass,
              maxLength: 16,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loading ? null : _submitForm(),
              validator: _validateConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Confirm the password',
                icon: const Icon(Icons.border_color),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideConfirmPass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _hideConfirmPass = !_hideConfirmPass),
                ),
                border: _border(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _loading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Form', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.black, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
