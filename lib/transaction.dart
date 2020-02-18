import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';

class Transaction extends StatefulWidget {
  final Ar.Wallet wallet;

  const Transaction({Key key, this.wallet}) : super(key: key);

  @override
  TransactionState createState() => TransactionState();
}

class TransactionState extends State<Transaction> {
  String _fileName;
  String _transactionCost = '0';
  String _content;
  List _tags = [];

  static const platform = const MethodChannel('armob.dev/signer');

  void _getContent() async {
    final fileName = await FilePicker.getFile();
    _fileName = (fileName.path).split('/').last;
    _content = fileName.readAsStringSync();
    final contentType = mime(_fileName);
    _transactionCost = await Ar.Transaction.transactionPrice(data: _content);
    _tags = [
      {
        'name': 'Content-Type',
        'value': (contentType == null ? "None" : contentType)
      },
      {'name': 'User-Agent', 'value': 'Armob 0.1'}
    ];
    setState(() {});
  }

  BigInt _base64ToInt(String encoded) {
    final b256 = new BigInt.from(256);
    encoded += new List.filled((4 - encoded.length % 4) % 4, "=").join();
    return base64Url
        .decode(encoded)
        .fold(BigInt.zero, (a, b) => a * b256 + new BigInt.from(b));
  }

  void _submitTransaction() async {
    final txAnchor = await Ar.Transaction.transactionAnchor();

    List<int> rawTransaction = widget.wallet.createTransaction(
        txAnchor, _transactionCost,
        data: _content, tags: _tags);

    try {
      List<int> signedTransaction =
          await platform.invokeMethod('signTransaction', {
        'rawTransaction': Uint8List.fromList(rawTransaction),
        'n': _base64ToInt(widget.wallet.jwk['n']).toString(),
        'd': _base64ToInt(widget.wallet.jwk['d']).toString()
      });
      print('Signed transaction is: $signedTransaction');
      final result = await widget.wallet.postTransaction(
          signedTransaction, txAnchor, _transactionCost,
          data: _content, tags: _tags);
      print(result);
    } on PlatformException catch (e) {
      print('Platform error occurred: $e');
    }
  }
  Widget tagTile(tag) {
      return ListTile(
        title: Text('${tag['name']}: ${tag['value']}'),
        );
  }

  List<Widget> tagList() {
    var tagList = <Widget>[];
      for (var tag in _tags) {
        tagList.add(tagTile(tag));
      }
    return tagList;
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Form')),
      body: Column(children: <Widget>[
        Row(children: <Widget>[
          Padding(child: Text('Transaction Cost'),padding: const EdgeInsets.all(20.0)),
          Padding(child: Text((Ar.winstonToAr(_transactionCost)).toString()),padding: const EdgeInsets.all(20.0))
        ]),
        Text('Transaction Tags', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
            child: (_content != null)
                ? ListView(children: tagList())
                : Text('No content yet')),
        ButtonBar(alignment: MainAxisAlignment.spaceAround, children: <Widget>[
          Column(children: <Widget>[
            IconButton(
                icon: Icon(Icons.file_upload), onPressed: () => _getContent()),
            Text('Pick Content')
          ]),
          Column(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.send),
                onPressed:
                    (_fileName != null) ? () => _submitTransaction() : null,
              ),
              Text('Submit Transaction')
            ],
          )
        ])
      ]),
    );
  }
}
