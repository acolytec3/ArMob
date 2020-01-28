import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:libarweave/libarweave.dart' as Ar;

class Wallet extends StatefulWidget {
  final Function(int index, String url) notifyParent;

  const Wallet({Key key, @required this.notifyParent}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  File _fileName;
  var _myWallet;
  var _balance;
  List _txHistory;
  
  void _openWallet() async {
    _fileName = await FilePicker.getFile();
    final walletString = _fileName.readAsStringSync();
    _myWallet = Ar.Wallet(walletString);
    _balance = await _myWallet.balance();
    setState(() {});
  }

  void _loadTxHistory() async {
    final txHistory = await _myWallet.transactionHistory();
    _txHistory = txHistory;
    setState(() {});
  }

  Widget transactionItem(transaction) {
    return ListTile(
      title: Text(transaction['id']),
      onTap: () => widget.notifyParent(1,'https://arweave.net/${transaction['id']}'));
  }

  List<Widget> buildTxHistory() {
    var txnList = <Widget>[];
    for (var txn in _txHistory){
      txnList.add(transactionItem(txn));
    }
    return txnList;
  }

  List<Widget> buildWallet() {
    List<Widget> widgetList = [];
    if (_fileName == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _openWallet(),
        child: Text("Open File Picker"),
      )));
    }
    if (_myWallet != null) {
      widgetList.add(Center(child: Text("Address: ${_myWallet.address}")));
      widgetList.add(Center(child: Text("Account Balance: $_balance")));
    }
    if (_txHistory == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _loadTxHistory(),
        child: Text("Load Transaction History"),
      )));
    } else {
      widgetList.add(Expanded(child:ListView(
        children: buildTxHistory())));
    }

    return widgetList;
  }

  @override
  Widget build(context) {
    return Column(children: buildWallet());
  }
}
