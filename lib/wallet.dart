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
  List<dynamic> _txList;

  //App components
  final storage = FlutterSecureStorage();
  String dropdownValue = 'All Transactions';

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
          _txList = jsonDecode(txns);
          Provider.of<WalletData>(context, listen: false).setTxs(_txList);
          setState(() {});
          _newTxns();
          _pendingTxns();
        } catch (__) {
          debugPrint('Error loading transactions: $__');
          _loadAllTxns();
        }
      } else {
        debugPrint('No tx found in history');
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
    _myWallet = null;
    _txList = [];
    setState(() {});
  }

  void _loadAllTxns() async {
    try {
      List allToTxnIds = await _myWallet.allTransactionsToAddress();
      List allFromTxnIds = await _myWallet.allTransactionsFromAddress();
      final allTxIds = allToTxnIds;
      allTxIds.addAll(allFromTxnIds);

      for (var i = 0; i < allTxIds.length; i++) {
        final txnDetail = await formTxn(allTxIds[i]);
        Provider.of<WalletData>(context, listen: false).addTx(txnDetail);
        setState(() {});
      }

      Provider.of<WalletData>(context, listen: false).setTxIds(allTxIds);

      _txList = Provider.of<WalletData>(context, listen: false).allTx;
      storage.write(key: 'txHistory', value: jsonEncode(_txList));
      storage.write(key: 'txIds', value: jsonEncode(allTxIds).toString());
      debugPrint('Wrote all txns to storage');
    } catch (__) {
      debugPrint("Error loading tx history: $__");
    }
  }

  _newTxns() async {
    List allTxnIds = await _myWallet.allTransactionsToAddress();
    List allFromTxns = await _myWallet.allTransactionsFromAddress();
    final histTxIds = Provider.of<WalletData>(context, listen: false).allTxIds;
    allTxnIds.addAll(allFromTxns);
    final newTxnIds = allTxnIds.where((txId) => !(histTxIds.contains(txId)));
    if (newTxnIds.length > 0) {
      debugPrint(newTxnIds.toString());
      for (var txn in newTxnIds) {
        final txnDetail = await formTxn(txn);
        Provider.of<WalletData>(context, listen: false).addTx(txnDetail);
      }
      _txList = Provider.of<WalletData>(context, listen: false).allTx;
      setState(() {});
    }
  }

  _pendingTxns() async {
    var allTx = Provider.of<WalletData>(context, listen: false).allTx;
    final pendingTx = allTx.where((txn) => (txn['status'] == 'pending'));
    List<dynamic> finalTx =
        allTx.where((txn) => (txn['status'] != 'pending')).toList();
    for (var txn in pendingTx) {
      try {
        final txnDetail = await formTxn(txn['id']);
        finalTx.add(txnDetail);
      } catch (__) {
        debugPrint('Error loading transaction: $__');
        finalTx.add({'id': txn['id'], 'status': 'pending'});
      }
    }
    Provider.of<WalletData>(context, listen: false).setTxs(finalTx);
    _txList = Provider.of<WalletData>(context, listen: false).allTx;
    setState(() {});
  }

  dynamic formTxn(String txId) async {
    Map<dynamic, dynamic> txnDetail = await Ar.Transaction.getTransaction(txId);
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
      ((Provider.of<WalletData>(context, listen: false).arweaveId != 'None'))
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
    return txnDetail;
  }

  Widget txnDetailWidget(BuildContext context, int index, String filter) {
    final txnDetail =
        _txList[index];
    List<Widget> txn;
    if (txnDetail['status'] != 'pending') {
      if (txnDetail['tags'] != null) {
        txn = [Text('Tags')];
        for (final tag in txnDetail['tags']) {
          txn.add(Row(
            children: <Widget>[
              Expanded(child: Text('Name: ${tag['name']}')),
              Expanded(child: Text('Name: ${tag['value']}'))
            ],
          ));
        }
      } else
        txn = [Text('No tags')];
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
            widget.notifyParent(1, "https://arweave.net/tx/${txnDetail['id']}");
          });
    }
  }

  void updateTxList(String txType){
    switch (txType) {
      case "Data Transactions": _txList = Provider.of<WalletData>(context, listen:false).allTx.where((txn) => txn['data'] != "").toList();
        break;
      case "AR Transactions": _txList = Provider.of<WalletData>(context, listen:false).allTx.where((txn) => txn['data'] == "").toList();
        break;
      default:
      _txList = Provider.of<WalletData>(context, listen:false).allTx;
    }
  }
  @override
  Widget build(context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text('Transactions'),
              actions: <Widget>[DropdownButton(style: TextStyle(color: Colors.white), dropdownColor: Colors.blue,
                items: <String>['All Transactions', 'Data Transactions', 'AR Transactions']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    dropdownValue = newValue;
                    updateTxList(newValue);
                  });
                },
                value: dropdownValue,
              ),]
            ),
            body:
                (Provider.of<WalletData>(context, listen: true).walletString ==
                        null)
                    ? (Center(child: Text('Open wallet to see transactions')))
                    : RefreshIndicator(
                        child: ( _txList != null ? ListView.builder(
                            itemBuilder: (BuildContext context, int index) =>
                                txnDetailWidget(context, index, dropdownValue),
                            itemCount:
                                _txList.length) : Center(child: Text("No txns retrieved"),)),
                        onRefresh: () async {
                          _newTxns();
                          _pendingTxns();
                          await Future.delayed(const Duration(seconds: 1));
                        }),
            floatingActionButton: (_myWallet != null)
                ? SpeedDial(animatedIcon: AnimatedIcons.view_list, children: [
                    (SpeedDialChild(
                        child: Icon(Icons.close),
                        label: "Close Wallet",
                        onTap: () => _removeWallet())),
                    SpeedDialChild(
                        child: Icon(Icons.cloud_upload),
                        label: 'Archive File',
                        onTap: () {
                          Route route = MaterialPageRoute(
                              builder: (context) => Transaction(
                                  wallet: _myWallet, transactionType: 'data'));
                          Navigator.push(context, route);
                        }),
                    SpeedDialChild(
                        child: Icon(Icons.attach_money),
                        label: 'Send AR',
                        onTap: () {
                          Route route = MaterialPageRoute(
                              builder: (context) => Transaction(
                                  wallet: _myWallet, transactionType: 'AR'));
                          Navigator.push(context, route);
                        })
                  ])
                : (FloatingActionButton.extended(
                    icon: Icon(Icons.attach_money),
                    label: Text('Login'),
                    onPressed: () => _openWallet(context)))));
  }
}
