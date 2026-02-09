import 'package:flutter/foundation.dart';

class ScanController extends ChangeNotifier {
  int _confidence = 0;

  int get confidence => _confidence;

  void setConfidence(int value) {
    _confidence = value.clamp(0, 100);
    notifyListeners();
  }
}
