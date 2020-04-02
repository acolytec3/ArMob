import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WalletData extends ChangeNotifier {
  String _walletString;
  double _currentBalance = 0;
  String _arweaveId = 'Wallet';
  List<dynamic> _allTx = [];
  List _allTxIds = [];

  String get walletString => _walletString;

  double get walletBalance => _currentBalance;

  String get arweaveId => _arweaveId;

  List get allTxIds => _allTxIds;

  List<dynamic> get allTx => _allTx;

  void updateWallet(String walletString, double balance) {
    _walletString = walletString;
    _currentBalance = balance;
    notifyListeners();
  }

  void updateArweaveId(String arweaveId) {
    _arweaveId = arweaveId;
    notifyListeners();
  }

  void addTxId(String txId) {
    _allTxIds.add(txId);
    notifyListeners();
  }

  void setTxIds(List txIds) {
    _allTxIds = txIds;
  }

  void setTxs(List<dynamic> txns) {
    _allTx = txns;
  }

  void addTx(dynamic txn) {
    _allTx.add(txn);
    _allTxIds.add(txn['id']);
    notifyListeners();
  }

  void deleteTx(dynamic txId){
    _allTx.remove(txId);
  }
}
