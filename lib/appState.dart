import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier {
  String _walletString;
  double _currentBalance = 0;

  String get walletString => _walletString;

  double get walletBalance => _currentBalance;

  void updateWallet(String walletString, double balance) {
    _walletString = walletString;
    _currentBalance = balance;
    notifyListeners();
  }
}
