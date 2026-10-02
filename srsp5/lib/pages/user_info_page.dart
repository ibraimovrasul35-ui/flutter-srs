import 'package:flutter/material.dart';

import '../models/user.dart';

class UserInfoPage extends StatelessWidget {
  final User user;

  const UserInfoPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(user.story.isEmpty ? '—' : user.story),
              trailing: Text(user.country),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.black),
              title: Text(user.phone),
            ),
            ListTile(
              leading: const Icon(Icons.mail, color: Colors.black),
              title: Text(user.email.isEmpty ? '—' : user.email),
            ),
          ],
        ),
      ),
    );
  }
}
