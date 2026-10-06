import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
      ),
      body: const Center(
        child: Text('Bem-vindo ao painel do administrador'),
      ),
    );
  }
}