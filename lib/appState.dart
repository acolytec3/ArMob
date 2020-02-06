import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier{
  File _walletFile;
  String _walletString;
  int _currentIndex = 0;
  String _url = "https://ftesrg4ur46h.arweave.net/nej78d0EJaSHwhxv0HAZkTGk0Dmc15sChUYfAC48QHI/index.html";

  String get walletString => _walletString;

  String get url => _url;

  void updateWallet(File wallet) {
    _walletFile = wallet;
    _walletString = wallet.readAsStringSync();
    notifyListeners();
  }

  void updateTabIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void updateUrl (String url) {
    _url = url;
    notifyListeners();
  }
}

