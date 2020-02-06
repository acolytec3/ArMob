import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'dart:io';

File _fileName;

class Wallet extends StatefulWidget {
  final Function(int index, String url) notifyParent;

  const Wallet({Key key, @required this.notifyParent}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  var _myWallet;
  var _balance;
  List _txHistory;
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();
    Ar.setPeer();
  }

  void _openWallet() async {
    _fileName = await FilePicker.getFile();
    Provider.of<WalletData>(context, listen: false).updateWallet(_fileName);
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
    try {
      final txHistory = await _myWallet.transactionHistory();
      _txHistory = txHistory;
      setState(() {});
    } catch (__) {
      print("Something went wrong trying to load transaction history");
    }
  }

  Widget transactionItem(transaction) {
    print(transaction['tags']);
    var contentType;
    try {
      contentType = transaction['tags'].singleWhere(
          (tag) => tag['name'] == 'Content-Type',
          orElse: () => "No content-type specified");
    } catch (__) {
      contentType = "No content-type specified";
    }
    return ListTile(
        title: Text(transaction['id']),
        subtitle: Text("Content type: ${contentType['value']}"),
        enabled: contentType != "No content-type specified",
        onTap: () {
          //Provider.of<WalletData>(context, listen:true).updateUrl("https://arweave.net/${transaction['id']}");
 //         flutterWebViewPlugin.reloadUrl("https://arweave.net/${transaction['id']}");
  //        flutterWebViewPlugin.dispose();
          widget.notifyParent(1, "https://arweave.net/${transaction['id']}");
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
    if (_txHistory == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: (_myWallet != null) ? () => _loadTxHistory() : null,
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
