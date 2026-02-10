import 'dart:convert';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:http/http.dart' as http;


class CrabApiService {
  static const _url = 'https://crabwatch.online/api/crabs';

  Future<List<Crab>> fetchCrabs() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load crabs (${response.statusCode})');
    }

    final body = json.decode(response.body);
    final List data = body['data'] ?? [];

    return data.map<Crab>((e) => Crab.fromJson(e)).toList();
  }
}