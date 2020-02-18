import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';

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
  String _fileName;

  //App components
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  final storage = FlutterSecureStorage();
  var loading = true;

  static const platform = const MethodChannel('armob.dev/signer');

  @override
  void initState() {
    super.initState();
    Ar.setPeer(peerAddress: 'https://arweave.net:443');
    readStorage();
  }

  //Loading/Unloading Wallet
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
    _loadTxHistory();
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

  //Transaction Submission
  BigInt _base64ToInt(String encoded) {
    final b256 = new BigInt.from(256);
    encoded += new List.filled((4 - encoded.length % 4) % 4, "=").join();
    return base64Url
        .decode(encoded)
        .fold(BigInt.zero, (a, b) => a * b256 + new BigInt.from(b));
  }

  void submitTransaction() async {
    final contentType = mime(_fileName);
    final txAnchor = await Ar.Transaction.transactionAnchor();
    final tags = [
      {
        'name': 'Content-Type',
        'value': (contentType == null ? "None" : contentType)
      },
      {'name': 'User-Agent', 'value': 'Armob 0.1'}
    ];
    List<int> rawTransaction = _myWallet.createTransaction(
        txAnchor, _transactionCost,
        data: _content, tags: tags);

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
          data: _content, tags: tags);
      print(result);
    } on PlatformException catch (e) {
      print('Platform error occurred: $e');
    }
  }

  void _getContent() async {
    final fileName = await FilePicker.getFile();
    _fileName = (fileName.path).split('/').last;
    _content = fileName.readAsStringSync();
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
            Center(
                child: Text(
                    'Transaction price: ${Ar.winstonToAr(_transactionCost)}')),
            Center(
                child: FlatButton(
                    child: Text('Submit Transaction'),
                    onPressed: () => submitTransaction()))
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
      contentType = {'value': "None"};
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

  @override
  Widget build(context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
                bottom: TabBar(tabs: [
              Icon(Icons.monetization_on),
              Icon(Icons.library_books),
            ])),
            body: TabBarView(children: [
              Center(
                child: Text('All Transactions -- coming soon!'),
              ),
              (Provider.of<WalletData>(context, listen: true).walletString ==
                      null)
                  ? (Center(child: Text('Open wallet to see transactions')))
                  : ListView(children: buildTxHistory())
            ]),
            floatingActionButton:
                SpeedDial(animatedIcon: AnimatedIcons.view_list, children: [
              SpeedDialChild(
                  child: Icon(Icons.attach_money),
                  label: "Open/Close Wallet",
                  onTap: () => (Provider.of<WalletData>(context, listen: true)
                              .walletString ==
                          null)
                      ? _openWallet()
                      : _removeWallet()),
              SpeedDialChild(
                  child: Icon(Icons.send),
                  label: 'Archive File',
                  onTap: () => _createTransaction())
            ])));
  }
}
