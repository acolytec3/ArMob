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
  //Wallet details
  Ar.Wallet _myWallet;
  var _balance;
  List _txHistory;

  //Transaction details
  String _content;
  String _transactionCost = '0';

  //App copmonents
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  final storage = FlutterSecureStorage();
  var loading = true;

  static const platform = const MethodChannel('armob.dev/signer');

  BigInt _base64ToInt(String encoded) {
    final b256 = new BigInt.from(256);
    encoded += new List.filled((4 - encoded.length % 4) % 4, "=").join();
    return base64Url
        .decode(encoded)
        .fold(BigInt.zero, (a, b) => a * b256 + new BigInt.from(b));
  }

  void postTransaction() async {
    final txAnchor = await Ar.Transaction.transactionAnchor();
    final tags = [{'name':'Content-Type','value':'text/plain'},{'name' : 'User-Agent', 'value' : 'Armob 0.1'}];
    List<int> rawTransaction = _myWallet.createTransaction(
        txAnchor, _transactionCost,
         data: _content, tags : tags);
         
    try {
      List<int> signedTransaction =
          await platform.invokeMethod('signTransaction', {
        'rawTransaction': Uint8List.fromList(rawTransaction),
        'n': _base64ToInt(_myWallet.jwk['n']).toString(),
        'd': _base64ToInt(_myWallet.jwk['d']).toString()
      });
      print('Signed transaction is: $signedTransaction');
      final result = await _myWallet.postTransaction(
          signedTransaction, txAnchor, _transactionCost,
                   data: _content, tags : tags);
      print(result);
    } on PlatformException catch (e) {
      print('Platform error occurred: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    Ar.setPeer(peerAddress: 'https://arweave.net:443');
    readStorage();
  }

  void readStorage() async {
    final storage = FlutterSecureStorage();
    var _wallet = await storage.read(key: 'walletString');
    if (_wallet != null) {
      _myWallet = Ar.Wallet(jsonWebKey: _wallet);
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
      _myWallet = Ar.Wallet(jsonWebKey: walletString);
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

  void _getContent() async {
    final _fileName = await FilePicker.getFile();
    _content = _fileName.readAsStringSync();
    _transactionCost = await Ar.Transaction.transactionPrice(data: _content);
    setState(() {});
  }

  void _createTransaction() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              content: Column(children: <Widget>[
            Center(child: Text('Create Transaction')),
            FlatButton(
                child: Text('Select Content'), onPressed: () => _getContent()),
            Center(child: Text('Transaction price: ${Ar.winstonToAr(_transactionCost)}')),
            Center(
                child: FlatButton(
                    child: Text('Post Transastion'),
                    onPressed: () => postTransaction()))
          ]));
        });
  }

  void _loadTxHistory() async {
    try {
      final txHistory = await _myWallet.dataTransactionHistory();
      _txHistory = txHistory;
      setState(() {});
    } catch (__) {
      print("Error loading tx history: $__");
    }
  }

  Widget transactionItem(transaction) {
    var contentType = {};
    try {
      contentType = transaction['tags'].singleWhere(
          (tag) => tag['name'] == 'Content-Type',
          orElse: () => "No content-type specified");
    } catch (__) {
      contentType = {'value':"None"};
    }
    return ListTile(
        title: Text(transaction['id']),
        subtitle: Text("Content type: ${contentType['value']}"),
        onTap: () {
          widget.notifyParent(1, "https://arweave.net/${transaction['id']}");
        });
  }

  List<Widget> buildTxHistory() {
    var txnList = <Widget>[];
    try {
      for (var txn in _txHistory) {
        txnList.add(transactionItem(txn));
      }
    } catch (__) {
      print('Error retrieving transactions: $__');
      txnList.add(Text('No transactions retrieved'));
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
      widgetList.add(FloatingActionButton(
        onPressed: () => _createTransaction(),
        child: Icon(Icons.attach_money),
      ));
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
