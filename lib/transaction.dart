import 'package:file_picker/file_picker.dart';
import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:mime_type/mime_type.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';
import 'dart:io';

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
  final _tagFormKey = GlobalKey<FormState>();
  static const platform = const MethodChannel('armob.dev/signer');

  @override
  void initState() { 
    super.initState();
    if (widget.transactionType.length > 0 && widget.transactionType != 'AR') {
      _getContent(path: widget.transactionType);
    } 
  }

  void _getContent({String path}) async {

    final file = path == null ? await FilePicker.getFile() : new File(path);
    _fileName = (file.path).split('/').last;
    try {
      _content = utf8.encode(file.readAsStringSync());
    } catch (__) {
      _content = file.readAsBytesSync();
    }

    final contentType = mime(_fileName);
    _calculateTxCost(numBytes: _content.length, targetAddress: _toAddress);
    _tags.add({
      'name': 'Content-Type',
      'value': (contentType == null ? "None" : contentType)
    });
    _tags.add({'name': 'User-Agent', 'value': 'Armob 0.1'});
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
    debugPrint('The transaction type is ${widget.transactionType == 'AR'}');
    List<int> rawTransaction = (widget.transactionType == 'AR')
        ? widget.wallet.createTransaction(txAnchor, _transactionCost,
            data: _content,
            tags: _tags,
            targetAddress: _toAddress,
            quantity: Ar.arToWinston(double.parse(_amount)))
        : widget.wallet.createTransaction(txAnchor, _transactionCost,
            data: _content, tags: _tags);

    try {
      final signedTransaction = await platform.invokeMethod('sign', {
        'rawTransaction': Uint8List.fromList(rawTransaction),
        'n': _base64ToInt(widget.wallet.jwk['n']).toString(),
        'd': _base64ToInt(widget.wallet.jwk['d']).toString(),
        'dp': _base64ToInt(widget.wallet.jwk['dp']).toString(),
        'dq': _base64ToInt(widget.wallet.jwk['dq']).toString()
      });

      final result = (widget.transactionType == 'AR')
          ? await widget.wallet.postTransaction(
              signedTransaction, txAnchor, _transactionCost,
              data: _content,
              tags: _tags,
              quantity: Ar.arToWinston(double.parse(_amount)),
              targetAddress: _toAddress)
          : await widget.wallet.postTransaction(
              signedTransaction, txAnchor, _transactionCost,
              data: _content, tags: _tags);

      debugPrint('Transaction status: ${result[0].statusCode}',
          wrapWidth: 1000);
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
    } catch (__) {
      debugPrint('Other error occurred: $__');
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

  dynamicTags() {
    var _name, _value;
    return Form(
        key: _tagFormKey,
        child: Column(children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Tag name cannot be blank';
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        _name = value;
                        setState(() {});
                      },
                    ),
                    padding: const EdgeInsets.all(5.0)),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Value',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Tag value cannot be blank';
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        _value = value;
                        setState(() {});
                      },
                    ),
                    padding: const EdgeInsets.all(5.0)),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                icon: Icon(Icons.playlist_add),
                onPressed: () {
                  if (_tagFormKey.currentState.validate()) {
                    _tagFormKey.currentState.save();
                    _tagFormKey.currentState.reset();
                  }
                  _tags.add({'name': _name, 'value': _value});
                  setState(() {});
                }),
            Text('Add Tag')
          ])
        ]));
  }

  Widget showARForm() {
    if (widget.transactionType == 'AR') {
      return (_toAddress == '')
          ? Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
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
                          padding: const EdgeInsets.all(5.0)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
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
                          padding: const EdgeInsets.all(5.0)),
                    ),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            _formKey.currentState.save();
                          }
                        }),
                    Text('Add Sendee/Amount')
                  ])
                ],
              ))
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
              Expanded(child:ListView(children: tagList())),
              dynamicTags(),
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
