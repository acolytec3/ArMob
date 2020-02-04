import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'package:arweave/browser.dart';
import 'package:provider/provider.dart';
import 'dart:io';

File _fileName;

class Wallet extends StatefulWidget {
  final Function(int index, File wallet) notifyParent;

  const Wallet({Key key, @required this.notifyParent}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  var _myWallet;
  var _balance;
  List _txHistory;

  @override
  void initState() {
    super.initState();
    Ar.setPeer();
  }

  void _openWallet() async {
    _fileName = await FilePicker.getFile();
    Provider.of<walletData>(context, listen: false).updateWallet(_fileName);
    final walletString = _fileName.readAsStringSync();
    try {
      _myWallet = Ar.Wallet(walletString);
    } catch (__) {
      print("Invalid Wallet File");
    }

    _balance = await _myWallet.balance();
    setState(() {});
  }

  void _loadTxHistory() async {
    final txHistory = await _myWallet.transactionHistory();
    _txHistory = txHistory;
    setState(() {});
  }

  Widget transactionItem(transaction) {
    print(transaction['tags']);
    final contentType = transaction['tags'].singleWhere(
        (tag) => tag['name'] == 'Content-Type',
        orElse: () => "No content-type specified");
    return ListTile(
        title: Text(transaction['id']),
        subtitle: Text("Content type: ${contentType['value']}"),
        enabled: contentType != "No content-type specified",
        onTap: () {
          webViewKey.currentState
              ?.loadURL("https://arweave.net/${transaction['id']}'");
          widget.notifyParent(1, _fileName);
        });
  }

  List<Widget> buildTxHistory() {
    var txnList = <Widget>[];
    for (var txn in _txHistory) {
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
        child: Text("Load Wallet"),
      )));
    }
    if (_myWallet != null) {
      widgetList.add(Center(child: Text("Address: ${_myWallet.address}")));
      widgetList.add(Center(child: Text("Account Balance: $_balance")));
    }
    if ((_myWallet!= null) && (_txHistory == null)) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _loadTxHistory(),
        child: Text("Load Transaction History"),
      )));
    } else {
      widgetList.add(Expanded(child: ListView(children: buildTxHistory())));
    }

    return widgetList;
  }

  @override
  Widget build(context) {
    return Column(children: buildWallet());
  }
}
