import 'package:flutter/material.dart';

class TransactionDetail extends StatelessWidget {
    final txn;

    const TransactionDetail({Key key, this.txn}) : super(key: key);
  @override
  Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Transaction Detail',),),
    body: Column(
      children: <Widget>[
        Text("Owner ${txn['owner']}"),
        Text("Transaction Fee ${txn['reward']}"),
        Text("Tags ${txn['tags'].toString()}")
        //TODO Add webview link to viewblock tx details
      ]));
  }
}