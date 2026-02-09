import 'package:flutter/material.dart';

import 'package:crab_maturity_ml_app/home/widget/header_logo.dart';

import 'package:crab_maturity_ml_app/home/pages/home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: const HeaderLogo(),
          ),
        ),
      ),

      body: HomeScreen(),
    );
  }
}
