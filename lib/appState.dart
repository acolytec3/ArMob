import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier{
  File _walletFile;
  String _walletString;

  String get walletString => _walletString;

  void updateWallet(File wallet) {
    _walletFile = wallet;
    _walletString = wallet.readAsStringSync();
    notifyListeners();
  }
}

