import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier {
  String _walletString;
  double _currentBalance = 0;
  String _arweaveId = 'Wallet';

  String get walletString => _walletString;

  double get walletBalance => _currentBalance;

  String get arweaveId => _arweaveId;

  void updateWallet(String walletString, double balance) {
    _walletString = walletString;
    _currentBalance = balance;
    notifyListeners();
  }

  void updateArweaveId(String arweaveId) {
    _arweaveId = arweaveId;
    notifyListeners();
  }
}
