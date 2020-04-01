import 'package:arweave/appState.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
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

  //App components
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
      final _arweaveId = await storage.read(key: 'arweaveId');
      if (_arweaveId != null) {
        Provider.of<WalletData>(context, listen: false)
            .updateArweaveId(_arweaveId);
      }

      final txns = await storage.read(key: 'txHistory');
      
      if (txns != null) {
        debugPrint('Txns retrieved: $txns', wrapWidth: 1000);
        try {
          final allTx = json.decode(txns);
          Provider.of<WalletData>(context, listen: false).setTxs(allTx);
          setState(() {});
          _newTxns();
        } catch (__) {
          debugPrint('Error loading transactions: $__');
          _loadAllTxns();
        }
      }
      else {
        debugPrint ('No tx found in history');
        _loadAllTxns();
      }

      final txIds = await storage.read(key: 'txIds');
      if (txIds != null) {
        try {
          final allTxIds = json.decode(txIds);
          Provider.of<WalletData>(context, listen: false).setTxIds(allTxIds);
        } catch (__) {
          debugPrint('Error loading transaction IDs: $__');
        }
      }
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
      var _arweaveId = await Ar.Transaction.arweaveIdLookup(_myWallet.address);
      if (_arweaveId != 'None') {
        Provider.of<WalletData>(context, listen: false)
            .updateArweaveId(_arweaveId);
        await storage.write(key: 'arweaveId', value: _arweaveId);
      }
      _loadDataTxs();
      _loadAllTxns();
      Provider.of<WalletData>(context, listen: false)
          .updateWallet(_walletString, _balance);
      setState(() {});
    } catch (__) {
      debugPrint("Error encountered - $__");
    }
  }

  void _removeWallet() async {
    await storage.deleteAll();
    Provider.of<WalletData>(context, listen: false).updateWallet(null, 0);
    Provider.of<WalletData>(context, listen: false).updateArweaveId('Wallet');
    Provider.of<WalletData>(context, listen: false).setTxs([]);
    Provider.of<WalletData>(context, listen: false).setTxIds([]);
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
      debugPrint('Error loading data tx history: $__');
    }
  }

  void _loadAllTxns() async {
    try {
      List allToTxnIds = await _myWallet.allTransactionsToAddress();
      List allFromTxnIds = await _myWallet.allTransactionsFromAddress();
      final allTxIds = allToTxnIds;
      allTxIds.addAll(allFromTxnIds);

      for (var i = 0; i < allTxIds.length; i++) {
        Map<dynamic, dynamic> txnDetail =
            await Ar.Transaction.getTransaction(allTxIds[i]);
        if (txnDetail['target'] != null) {
          if (txnDetail['target'] == _myWallet.address) {
            txnDetail['to'] =
                Provider.of<WalletData>(context, listen: false).arweaveId;
          } else {
            txnDetail['to'] =
                await Ar.Transaction.arweaveIdLookup(txnDetail['target']);
            if (txnDetail['to'] == 'None') {
              txnDetail['to'] = txnDetail['target'];
            }
          }
        } else
          txnDetail['to'] = 'None';
        if (txnDetail['owner'] == _myWallet.address) {
          ((Provider.of<WalletData>(context, listen: false).arweaveId !=
                  'None'))
              ? txnDetail['from'] =
                  Provider.of<WalletData>(context, listen: false).arweaveId
              : txnDetail['from'] = _myWallet.address;
        } else {
          txnDetail['from'] =
              await Ar.Transaction.arweaveIdLookup(txnDetail['owner']);
          if (txnDetail['from'] == 'None') {
            txnDetail['from'] = txnDetail['owner'];
          }
        }

        Provider.of<WalletData>(context, listen: false).addTx(txnDetail);
        setState(() {});
        
      }
      Provider.of<WalletData>(context, listen: false).setTxIds(allTxIds);
      storage.write(
          key: 'txHistory',
          value: jsonEncode(Provider.of<WalletData>(context, listen: false)
              .allTx
              .toString()));
      storage.write(key: 'txIds', value: jsonEncode(allTxIds).toString());
      debugPrint('Wrote all txns to storage');
    } catch (__) {
      debugPrint("Error loading tx history: $__");
    }
  }

  void _newTxns() async {
    List allTxnIds = await _myWallet.allTransactionsToAddress();
    List allFromTxns = await _myWallet.allTransactionsFromAddress();
    final histTxIds = Provider.of<WalletData>(context, listen: false).allTxIds;
    allTxnIds.addAll(allFromTxns);
    List newTxnIds = allTxnIds.where((txId) => !(histTxIds.contains(txId)));
    if (newTxnIds.length > 0) {
      debugPrint(newTxnIds.toString());
      for (var i = 0; i < newTxnIds.length; i++) {
        final txnDetail = await Ar.Transaction.getTransaction(newTxnIds[i]);
        Provider.of<WalletData>(context, listen: false).addTx(txnDetail);
      }
      setState(() {});
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
      debugPrint('Error retrieving transactions: $__');
      txnList.add(Text('No transactions retrieved'));
    }
    return txnList;
  }

  Widget txnDetailWidget(BuildContext context, int index) {
    final txnDetail =
        Provider.of<WalletData>(context, listen: false).allTx[index];
    List<Widget> txn;
    if (txnDetail['status'] != 'pending') {
      

      if (txnDetail['tags'] != null) {
        txn = [Text('Tags')];
        for (final tag in txnDetail['tags']) {
          txn.add(Row(
            children: <Widget>[
              Text('Name: ${tag['name']}'),
              Text('Name: ${tag['value']}')
            ],
          ));
        }
      } else txn = [Text('No tags')];
      return ExpansionTile(
          title: ListTile(
              title: Text(txnDetail['id']),
              onLongPress: () {
                widget.notifyParent(
                    1, "https://viewblock.io/arweave/tx/${txnDetail['id']}");
              }),
          subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Amount ${Ar.winstonToAr(txnDetail['quantity'])} AR'),
                Text(
                    'Fee: ${Ar.winstonToAr(txnDetail['reward']).toString()} AR'),
                Text('From: ${txnDetail['from']}'),
                Text('To: ${txnDetail['to']}')
              ]),
          initiallyExpanded: false,
          children: <Widget>[
            Column(children: txn, crossAxisAlignment: CrossAxisAlignment.start)
          ]);
    } else {
      return ListTile(
          title: Text(txnDetail['id']),
          subtitle: Text('Transaction pending'),
          onLongPress: () {
            widget.notifyParent(
                1, "https://arweave.net/tx/${txnDetail['id']}");
          });
    }
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
                  : ListView.builder(
                      itemBuilder: (BuildContext context, int index) =>
                          txnDetailWidget(context, index),
                      itemCount: Provider.of<WalletData>(context, listen: true)
                          .allTx
                          .length),
              (Provider.of<WalletData>(context, listen: true).walletString ==
                      null)
                  ? (Center(child: Text('Open wallet to see transactions')))
                  : ListView(children: buildDataTxHistory())
            ]),
            floatingActionButton: (_myWallet != null)
                ? SpeedDial(animatedIcon: AnimatedIcons.view_list, children: [
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
                  ])
                : (FloatingActionButton.extended(
                    icon: Icon(Icons.attach_money),
                    label: Text('Login'),
                    onPressed: () => _openWallet(context)))));
  }
}
