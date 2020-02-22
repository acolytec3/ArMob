import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:arweave/transaction.dart';
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
  List _dataTxHistory;
  List<dynamic> _allTx = [];

  //App components
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  final storage = FlutterSecureStorage();
  var loading = true;

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

  void _openWallet(context) async {
    var _fileName;
    var _walletString;
    try {
      _fileName = await FilePicker.getFile();
      _walletString = _fileName.readAsStringSync();
      _myWallet = Ar.Wallet(jsonWebKey: _walletString);
      await storage.write(key: "walletString", value: _walletString);
      _balance = await _myWallet.balance();
      _loadDataTxs();
      _loadAllTxns();
      Provider.of<WalletData>(context, listen: false)
          .updateWallet(_walletString, _balance);
      setState(() {});
    } catch (__) {
      print("Invalid Wallet File");
    }
  }

  void _removeWallet() async {
    await storage.deleteAll();
    Provider.of<WalletData>(context, listen: false).updateWallet(null, 0);
    _balance = 0;
    _dataTxHistory = null;
    _myWallet = null;
    setState(() {});
  }

  void _loadDataTxs() async {
    try {
      final dataTxHistory = await _myWallet.dataTransactionHistory();
      _dataTxHistory = dataTxHistory;
      setState(() {});
    } catch (__) {
      print('Error loading data tx history: $__');
    }
  }

  void _loadAllTxns() async {
    final txHistoryString = jsonDecode(await storage.read(key: 'txHistory'));
    //TODO: read tx history from storage instead of pinging remote node
    try {
      List allToTxns = await _myWallet.allTransactionsToAddress();
      List allFromTxns = await _myWallet.allTransactionsFromAddress();
      _allTx = allToTxns;
      _allTx.addAll(allFromTxns);
      for (var i = 0; i < _allTx.length; i++) {
        _allTx[i] = {'id': _allTx[i]};
      }
      setState(() {});
      for (var i = 0; i < _allTx.length; i++) {
        final txnDetail = await Ar.Transaction.getTransaction(_allTx[i]['id']);
        print(txnDetail);
        _allTx[i] = txnDetail;
        setState(() {});
      }
      storage.write(key: 'txHistory', value: jsonEncode(_allTx));
    } catch (__) {
      print("Error loading tx history: $__");
    }
  }

  Widget dataTransactionItem(transaction) {
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

  List<Widget> buildDataTxHistory() {
    var txnList = <Widget>[];
    try {
      for (var txn in _dataTxHistory) {
        txnList.add(dataTransactionItem(txn));
      }
    } catch (__) {
      print('Error retrieving transactions: $__');
      txnList.add(Text('No transactions retrieved'));
    }
    return txnList;
  }

  List<Widget> buildTxHistory() {
    var txnList = <Widget>[];
    try {
      for (var x = 0; x < _allTx.length; x++) {
        if (_allTx[x].containsKey('reward')) {
          List<Widget> txn = [Text('Tags')];
    
          for (final tag in _allTx[x]['tags']) {
            print(tag);
            txn.add(Row(children: <Widget>[
              Text('Name: ${tag['name']}'),
              Text('Name: ${tag['value']}')
            ],));
          }

          txnList.add(ExpansionTile(
              title: ListTile(
                  title: Text(_allTx[x]['id']),
                  onLongPress: () {
                    widget.notifyParent(1,
                        "https://viewblock.io/arweave/tx/${_allTx[x]['id']}");
                  }),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Amount ${Ar.winstonToAr(_allTx[x]['quantity'])} AR'),
                    Text(
                        'Fee: ${Ar.winstonToAr(_allTx[x]['reward']).toString()} AR'),
                  ]),
              initiallyExpanded: false,
              children: <Widget>[
                Column(children: txn
                , crossAxisAlignment: CrossAxisAlignment.start)
              ]));
        } else {
          txnList.add(ListTile(
              title: Text(_allTx[x]['id']),
              onLongPress: () {
                widget.notifyParent(
                    1, "https://viewblock.io/arweave/tx/${_allTx[x]['id']}");
              }));
        }
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
              Tab(text: 'All Transactions', icon: Icon(Icons.monetization_on)),
              Tab(text: 'Data Transactions', icon: Icon(Icons.library_books)),
            ])),
            body: TabBarView(children: [
              (Provider.of<WalletData>(context, listen: true).walletString ==
                      null)
                  ? (Center(child: Text('Open wallet to see transactions')))
                  : ListView(children: buildTxHistory()),
              (Provider.of<WalletData>(context, listen: true).walletString ==
                      null)
                  ? (Center(child: Text('Open wallet to see transactions')))
                  : ListView(children: buildDataTxHistory())
            ]),
            floatingActionButton: (_myWallet != null) ? SpeedDial(
                animatedIcon: AnimatedIcons.view_list,
                children: 
                   [
                        (SpeedDialChild(
                            child: Icon(Icons.attach_money),
                            label: "Close Wallet",
                            onTap: () => _removeWallet())),
                        SpeedDialChild(
                            child: Icon(Icons.send),
                            label: 'Archive File',
                            onTap: () {
                              Route route = MaterialPageRoute(
                                  builder: (context) =>
                                      Transaction(wallet: _myWallet));
                              Navigator.push(context, route);
                            })
                      ]
                    
                      ): 
                        (FloatingActionButton.extended(
                            icon: Icon(Icons.attach_money),
                            label: Text('Login'),
                            onPressed: () => _openWallet(context)))));
  }
}
