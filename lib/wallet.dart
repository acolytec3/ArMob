import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';

class Wallet extends StatefulWidget {
  final Function(int index, String url) notifyParent;

  const Wallet({Key key, @required this.notifyParent}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  var _myWallet;
  var _balance;
  var loading = true;
  List _txHistory;
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  final storage = FlutterSecureStorage();

  static const platform = const MethodChannel('armob.dev/signer');

List<int> _base64ToBytes(String encoded) {
  encoded += new List.filled((4 - encoded.length % 4) % 4, "=").join();
  return base64Url.decode(encoded);
}

BigInt _base64ToInt(String encoded) {
  final b256 = new BigInt.from(256);
  return _base64ToBytes(encoded)
      .fold(BigInt.zero, (a, b) => a * b256 + new BigInt.from(b));
}
  Future<List<int>> signTransaction (Uint8List rawTransaction) async {
    try {
      List<int> signedTransaction = await platform.invokeMethod('signTransaction',{'rawTransaction': rawTransaction, 'n' : _base64ToInt(_myWallet.jwk['n']).toString(), 'd': _base64ToInt(_myWallet.jwk['d']).toString()});
      print('Signed transaction is: $signedTransaction');
      return signedTransaction;
    }
    on PlatformException catch (e) {
      print('Platform error occurred: $e');
    }  
  }

  @override
  void initState() {
    super.initState();
    Ar.setPeer();
    readStorage();
  }

  void readStorage() async {
    final storage = FlutterSecureStorage();
    var _wallet = await storage.read(key: 'walletString');
    if (_wallet != null) {
      _myWallet = Ar.Wallet(_wallet);
      _balance = await _myWallet.balance();
      Provider.of<WalletData>(context, listen: false)
          .updateWallet(_wallet, _balance);
    }
    loading = false;
  }

  void _openWallet() async {
    final _fileName = await FilePicker.getFile();
    final walletString = _fileName.readAsStringSync();

    await storage.write(key: "walletString", value: walletString);

    try {
      _myWallet = Ar.Wallet(walletString);
    } catch (__) {
      print("Invalid Wallet File");
    }

    _balance = await _myWallet.balance();

    Provider.of<WalletData>(context, listen: false)
        .updateWallet(walletString, _balance);
    setState(() {});
  }

  void _removeWallet() async {
    await storage.deleteAll();
    Provider.of<WalletData>(context, listen: false).updateWallet(null, 0);
    _balance = 0;
    _txHistory = null;
    _myWallet = null;
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
    if (Provider.of<WalletData>(context, listen: true).walletString == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _openWallet(),
        child: Text("Load Wallet"),
      )));
    } else {
      widgetList.add(Center(
          child: RaisedButton(
              onPressed: () => _removeWallet(), child: Text("Remove Wallet"))));
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
    return Column(
        children: loading
            ? [
                Center(
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: const CircularProgressIndicator()))
              ]
            : buildWallet());
  }
}
