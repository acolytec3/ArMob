import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';

class Transaction extends StatefulWidget {
  final Ar.Wallet wallet;
  final transactionType;

  const Transaction({Key key, this.wallet, this.transactionType})
      : super(key: key);

  @override
  TransactionState createState() => TransactionState();
}

class TransactionState extends State<Transaction> {
  String _fileName;
  String _transactionCost = '0';
  List<int> _content;
  List _tags = [];
  String _toAddress = '';
  String _transactionStatus;
  String _transactionResult;
  String _amount;
  String _displayTxCost = '0';
  final _formKey = GlobalKey<FormState>();

  static const platform = const MethodChannel('armob.dev/signer');

  void _getContent() async {
    final file = await FilePicker.getFile();
    _fileName = (file.path).split('/').last;
    try {
      _content = utf8.encode(file.readAsStringSync());
    } catch (__) {
      _content = file.readAsBytesSync();
    }

    final contentType = mime(_fileName);
    _calculateTxCost(numBytes: _content.length, targetAddress: _toAddress);
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

  void _calculateTxCost(
      {int numBytes = 0, String data, String targetAddress = ''}) async {
    _transactionCost = await Ar.Transaction.transactionPrice(
        numBytes: numBytes, data: data, targetAddress: targetAddress);
    if (_amount != null) {
      final totalCost =
          Ar.winstonToAr(_transactionCost) + double.parse(_amount);
      _displayTxCost = Ar.arToWinston(totalCost);
    } else
      _displayTxCost = _transactionCost;
    setState(() {});
  }

  void _submitTransaction() async {
    final txAnchor = await Ar.Transaction.transactionAnchor();

    List<int> rawTransaction = (widget.transactionType == 'AR') ? widget.wallet.createTransaction(
        txAnchor, _transactionCost,
        data: _content,
        tags: _tags,
        targetAddress: _toAddress,
        quantity: Ar.arToWinston(double.parse(_amount))) :  widget.wallet.createTransaction(
        txAnchor, _transactionCost,
        data: _content,
        tags: _tags);

    try {
      List<int> signedTransaction =
          await platform.invokeMethod('signTransaction', {
        'rawTransaction': Uint8List.fromList(rawTransaction),
        'n': _base64ToInt(widget.wallet.jwk['n']).toString(),
        'd': _base64ToInt(widget.wallet.jwk['d']).toString()
      });

      final result = (widget.transactionType == 'AR') ? await widget.wallet.postTransaction(
          signedTransaction, txAnchor, _transactionCost,
          data: _content,
          tags: _tags,
          quantity: Ar.arToWinston(double.parse(_amount)),
          targetAddress: _toAddress) :
          await widget.wallet.postTransaction(
          signedTransaction, txAnchor, _transactionCost,
          data: _content, tags: _tags);

      debugPrint('Transaction status: ${result[0].statusCode}');
      try {
        _transactionStatus = result[0].statusCode.toString();
      } catch (__) {
        _transactionStatus = '500';
      }
      if (_transactionStatus == '200') {
        _transactionResult =
            'Transaction ID - ${result[1]} - has been submitted!';
        final txnDetail = {'id': result[1], 'status': 'pending'};
        Provider.of<WalletData>(context, listen: false).addTx(txnDetail);
      } else {
        _transactionResult = 'Transaction could not be submitted.';
      }
      setState(() {});
    } on PlatformException catch (e) {
      debugPrint('Platform error occurred: $e');
    }
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pop(context);
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

  Widget showARForm() {
    if (widget.transactionType == 'AR') {
      return (_toAddress == '')
          ? Form(
              key: _formKey,
              child: Column(children: [
                Padding(
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'To',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Address cannot be blank';
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        _toAddress = value;
                        _calculateTxCost(targetAddress: _toAddress);
                      },
                    ),
                    padding: const EdgeInsets.all(20.0)),
                Padding(
                    child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Amount',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Amount cannot be 0';
                          }
                          return null;
                        },
                        onSaved: (String value) {
                          _amount = value;
                          _calculateTxCost();
                          setState(() {});
                        }),
                    padding: const EdgeInsets.all(20.0)),
                Column(children: [
                  IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();
                        }
                      }),
                  Text('Add Sendee/Amount')
                ])
              ]))
          : Column(children: [
              Row(children: <Widget>[
                Text('To: '),
                Expanded(child: Text(_toAddress))
              ]),
              Row(children: <Widget>[
                Text('Amount: '),
                Expanded(child: Text(_amount))
              ])
            ]);
    } else {
      return Container();
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Form')),
      body: (_transactionStatus == null)
          ? Column(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                    child: Text('Transaction Cost'),
                    padding: const EdgeInsets.all(20.0)),
                Padding(
                    child: Text((Ar.winstonToAr(_displayTxCost)).toString()),
                    padding: const EdgeInsets.all(20.0))
              ]),
              Text('Transaction Tags',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                  child: (_content != null)
                      ? ListView(children: tagList())
                      : Text('No content yet')),
              showARForm(),
              ButtonBar(
                  alignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.file_upload),
                          onPressed: () => _getContent()),
                      Text('Pick Content')
                    ]),
                    Column(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: ((_fileName != null) || (_amount != null))
                              ? () => _submitTransaction()
                              : null,
                        ),
                        Text('Submit Transaction')
                      ],
                    )
                  ])
            ])
          : Center(
              child: Padding(
                  child: Text(_transactionResult,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  padding: const EdgeInsets.all(20.0)),
            ),
    );
  }
}
