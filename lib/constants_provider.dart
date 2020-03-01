import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConstantsProvider extends ChangeNotifier {
  double _dampeningConstant = 100;
  double _objectMass = 1;
  double _mechanicalEnergy = 200;
  double _simSpeed = 0.25;
  double _gravity = 9.807;
  double _length = 1;
  ThemeMode _theme = ThemeMode.system;

  double get K => _dampeningConstant;
  double get M => _objectMass;
  double get Em => _mechanicalEnergy;
  double get speed => _simSpeed;
  double get g => _gravity;
  double get l => _length;
  ThemeMode get theme => _theme;

  set K(double d) {
    if (d != _dampeningConstant && d > 0) {
      _dampeningConstant = d;
      notifyListeners();
    }
  }

  set M(double d) {
    if (d != _objectMass && d > 0) {
      _objectMass = d;
      notifyListeners();
    }
  }

  set Em(double d) {
    if (d != _mechanicalEnergy && d > 0) {
      _mechanicalEnergy = d;
      notifyListeners();
    }
  }

  set speed(double d) {
    if (d != _simSpeed && d > 0) {
      _simSpeed = d;
      notifyListeners();
    }
  }

  set theme(ThemeMode t) {
    if (t != _theme) {
      _theme = t;
      notifyListeners();
    }
  }

  void incK() => K += 5.0;
  void decK() => K -= 5.0;

  void incM() => M += 5.0;
  void decM() => M -= 5.0;

  void incEm() => Em += 5.0;
  void decEm() => Em -= 5.0;

  void incS() => speed = (_simSpeed / 0.25).round() * 0.25 + 0.25;
  void decS() => speed = (_simSpeed / 0.25).round() * 0.25 - 0.25;
}
