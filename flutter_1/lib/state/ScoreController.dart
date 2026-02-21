import 'package:flutter/material.dart';

class ScoreController extends ChangeNotifier {
  double _score = 0;
  bool _subscriptionActive = false;

  double get score => _score;
  bool get subscriptionActive => _subscriptionActive;

  void setScore(double newScore) {
    _score = newScore;
    notifyListeners();
  }

  void setSubscription(bool active) {
    _subscriptionActive = active;
    notifyListeners();
  }
}
