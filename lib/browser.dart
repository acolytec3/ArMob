import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'dart:typed_data';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:libarweave/libarweave.dart' as Ar;

final webViewKey = GlobalKey<WebViewContainerState>();

const rpcURL = "https://ropsten.infura.io/v3/c4809a978c5b48c8a5b8fdc9133cef42";
var httpClient = new Client();
var web3 = new Web3Client(rpcURL, httpClient);

Future<String> resolve(namehash) async {
  final registryAbi =
      """[ { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "resolver", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "owner", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "label", "type": "bytes32" }, { "name": "owner", "type": "address" } ], "name": "setSubnodeOwner", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "ttl", "type": "uint64" } ], "name": "setTTL", "outputs": [], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "ttl", "outputs": [ { "name": "", "type": "uint64" } ], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "resolver", "type": "address" } ], "name": "setResolver", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "owner", "type": "address" } ], "name": "setOwner", "outputs": [], "payable": false, "type": "function" }, { "inputs": [], "payable": false, "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "owner", "type": "address" } ], "name": "Transfer", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": true, "name": "label", "type": "bytes32" }, { "indexed": false, "name": "owner", "type": "address" } ], "name": "NewOwner", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "resolver", "type": "address" } ], "name": "NewResolver", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "ttl", "type": "uint64" } ], "name": "NewTTL", "type": "event" } ]""";
  final registryContract = DeployedContract(
      ContractAbi.fromJson(registryAbi, "Registry"),
      EthereumAddress.fromHex("0x112234455c3a32fd11230c42e7bccd4a84e02010"));
  final resolver = registryContract.function('resolver');
  final resolverAddress = await web3
      .call(contract: registryContract, function: resolver, params: [namehash]);
  final resolverAbi =
      """[ { "constant": true, "inputs": [ { "name": "interfaceID", "type": "bytes4" } ], "name": "supportsInterface", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "pure", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "data", "type": "bytes" } ], "name": "setDNSRecords", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "key", "type": "string" }, { "name": "value", "type": "string" } ], "name": "setText", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "interfaceID", "type": "bytes4" } ], "name": "interfaceImplementer", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "contentTypes", "type": "uint256" } ], "name": "ABI", "outputs": [ { "name": "", "type": "uint256" }, { "name": "", "type": "bytes" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "x", "type": "bytes32" }, { "name": "y", "type": "bytes32" } ], "name": "setPubkey", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "hash", "type": "bytes" } ], "name": "setContenthash", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "addr", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "name", "type": "bytes32" } ], "name": "hasDNSRecords", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "key", "type": "string" } ], "name": "text", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "contentType", "type": "uint256" }, { "name": "data", "type": "bytes" } ], "name": "setABI", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "name", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "name", "type": "string" } ], "name": "setName", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "name", "type": "bytes32" }, { "name": "resource", "type": "uint16" } ], "name": "dnsRecord", "outputs": [ { "name": "", "type": "bytes" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "clearDNSZone", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "contenthash", "outputs": [ { "name": "", "type": "bytes" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": true, "inputs": [ { "name": "node", "type": "bytes32" } ], "name": "pubkey", "outputs": [ { "name": "x", "type": "bytes32" }, { "name": "y", "type": "bytes32" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "addr", "type": "address" } ], "name": "setAddr", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "interfaceID", "type": "bytes4" }, { "name": "implementer", "type": "address" } ], "name": "setInterface", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" }, { "constant": true, "inputs": [ { "name": "", "type": "bytes32" }, { "name": "", "type": "address" }, { "name": "", "type": "address" } ], "name": "authorisations", "outputs": [ { "name": "", "type": "bool" } ], "payable": false, "stateMutability": "view", "type": "function" }, { "inputs": [ { "name": "_ens", "type": "address" } ], "payable": false, "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": true, "name": "owner", "type": "address" }, { "indexed": true, "name": "target", "type": "address" }, { "indexed": false, "name": "isAuthorised", "type": "bool" } ], "name": "AuthorisationChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": true, "name": "indexedKey", "type": "string" }, { "indexed": false, "name": "key", "type": "string" } ], "name": "TextChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "x", "type": "bytes32" }, { "indexed": false, "name": "y", "type": "bytes32" } ], "name": "PubkeyChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "name", "type": "string" } ], "name": "NameChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": true, "name": "interfaceID", "type": "bytes4" }, { "indexed": false, "name": "implementer", "type": "address" } ], "name": "InterfaceChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "name", "type": "bytes" }, { "indexed": false, "name": "resource", "type": "uint16" }, { "indexed": false, "name": "record", "type": "bytes" } ], "name": "DNSRecordChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "name", "type": "bytes" }, { "indexed": false, "name": "resource", "type": "uint16" } ], "name": "DNSRecordDeleted", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" } ], "name": "DNSZoneCleared", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "hash", "type": "bytes" } ], "name": "ContenthashChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": false, "name": "a", "type": "address" } ], "name": "AddrChanged", "type": "event" }, { "anonymous": false, "inputs": [ { "indexed": true, "name": "node", "type": "bytes32" }, { "indexed": true, "name": "contentType", "type": "uint256" } ], "name": "ABIChanged", "type": "event" }, { "constant": false, "inputs": [ { "name": "node", "type": "bytes32" }, { "name": "target", "type": "address" }, { "name": "isAuthorised", "type": "bool" } ], "name": "setAuthorisation", "outputs": [], "payable": false, "stateMutability": "nonpayable", "type": "function" } ]""";
  final resolverContract = DeployedContract(
      ContractAbi.fromJson(resolverAbi, "Resolver"), resolverAddress[0]);
  final supportInterface = resolverContract.function("supportsInterface");
  final result = await web3.call(
      contract: resolverContract,
      function: supportInterface,
      params: [hexToBytes("0x59d1d43c")]);
  if (result[0] == true) {
    final getText = resolverContract.function("text");
    final url = await web3.call(
        contract: resolverContract,
        function: getText,
        params: [namehash, "url"]);
    print(url);
    return url[0].toString();
  } else
    print("Resolver doesn't support Text/url record resolution");
  return ("URL resolution not supported");
}

Uint8List nameHash(String name) {
  if (name == "") {
    final hash = Uint8List(32);
    return hash;
  } else {
    var hash = Uint8List(32);
    final List<String> splitName = name.split(".");
    for (var i = splitName.length - 1; i >= 0; i--) {
      final labelHash = keccakUtf8(splitName[i]);
      hash = keccak256(Uint8List.fromList(hash + labelHash));
    }
    return hash;
  }
}

class EnsName extends StatefulWidget {
  final String url;
  const EnsName({Key key, this.url}) : super(key: key);
  @override
  EnsNameState createState() => EnsNameState();
}

class EnsNameState extends State<EnsName> {
  String name;
  String url;

  void setUrl(resolvedName) async {
    name = resolvedName;
    try{
      final arTx = await resolve(nameHash(name));
      url = 'https://arweave.net/' + arTx.toString();
      webViewKey.currentState?.loadURL(url);
    }
   catch(__) {
      print("Name could not be resolved");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Address',
            ),
            onSubmitted: (value) {
              setUrl(value);
            }),
        Expanded(child: WebViewContainer(key: webViewKey)),
      ],
    );
  }
}

class WebViewContainer extends StatefulWidget {
  WebViewContainer({Key key}) : super(key: key);

  @override
  WebViewContainerState createState() => WebViewContainerState();
}

class WebViewContainerState extends State<WebViewContainer> {
  WebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return WebView(
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      initialUrl: "https://arweave.net",
    );
  }

  void reloadWebView() {
    _webViewController?.reload();
  }

  void loadURL(String url) {
    _webViewController?.loadUrl(url);
  }
}

class Wallet extends StatefulWidget {
  final Function(int index) notifyParent;

  const Wallet({Key key, @required this.notifyParent}) : super(key: key);

  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  File _fileName;
  var _myWallet;
  var _balance;
  List _txHistory;

  void _openWallet() async {
    _fileName = await FilePicker.getFile();
    final walletString = _fileName.readAsStringSync();
    try{
    _myWallet = Ar.Wallet(walletString);
    }
    catch(__){
      print("Invalid Wallet File");
    }

    _balance = await _myWallet.balance();
    setState(() {});
  }

  void _loadTxHistory() async {
    final txHistory = await _myWallet.transactionHistory();
    _txHistory = txHistory;
    setState(() {});
  }

  Widget transactionItem(transaction) {
    return ListTile(
        title: Text(transaction['id']),
        onTap: () {
          webViewKey.currentState
              ?.loadURL("https://arweave.net/${transaction['id']}'");
          widget.notifyParent(1);
        });
  }

  List<Widget> buildTxHistory() {
    var txnList = <Widget>[];
    for (var txn in _txHistory) {
      txnList.add(transactionItem(txn));
    }
    return txnList;
  }

  List<Widget> buildWallet() {
    List<Widget> widgetList = [];
    if (_fileName == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _openWallet(),
        child: Text("Load Wallet"),
      )));
    }
    if (_myWallet != null) {
      widgetList.add(Center(child: Text("Address: ${_myWallet.address}")));
      widgetList.add(Center(child: Text("Account Balance: $_balance")));
    }
    if (_txHistory == null) {
      widgetList.add(Center(
          child: RaisedButton(
        onPressed: () => _loadTxHistory(),
        child: Text("Load Transaction History"),
      )));
    } else {
      widgetList.add(Expanded(child: ListView(children: buildTxHistory())));
    }

    return widgetList;
  }

  @override
  Widget build(context) {
    return Column(children: buildWallet());
  }
}
