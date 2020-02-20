import 'package:flutter/material.dart';

class TransactionDetail extends StatelessWidget {
    final txn;

    const TransactionDetail({Key key, this.txn}) : super(key: key);
  @override
  Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: Text('Transaction Detail',),),
    body: Text(txn.toString()));
  }
}