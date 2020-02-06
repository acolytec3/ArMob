import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier{
  File _walletFile;
  String _walletString;
  double _currentBalance = 0;

  int _currentIndex = 0;

  String get walletString => _walletString;

  double get walletBalance => _currentBalance;

  void updateWallet(File wallet, double balance) {
    _walletFile = wallet;
    _walletString = wallet.readAsStringSync();
    _currentBalance = balance;
    notifyListeners();
  }

  void updateTabIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

}

