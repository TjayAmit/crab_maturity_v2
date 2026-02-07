import 'dart:convert';
import 'package:crab_maturity_ml_app/feature/crabs/models/crab_model.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<List<Crab>> loadCrabs() async {
  final String response = await rootBundle.loadString('assets/data/data.json');
  final data = json.decode(response);
  final List<dynamic> crabsJson = data['crabs'];
  return crabsJson.map((json) => Crab.fromJson(json)).toList();
}
