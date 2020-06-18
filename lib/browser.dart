import 'dart:convert';
import 'package:arweave/ens.dart';
import 'package:jose/jose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';
import 'package:libarweave/libarweave.dart' as Arweave;
import 'package:flutter/services.dart';
import 'dart:typed_data';

var loginFunction, signFunction;

final webviewKey = GlobalKey<WebViewContainerState>();
final walletAPI = '''
const walletAPI = {
    getPublicKey : async function () {
        return window.flutter_inappwebview.callHandler('address').then(function (result) {
            var walletString = JSON.stringify(result);
            return walletString;
    })},
    sign : async function (rawTransaction) {
        console.log(rawTransaction);
        return window.flutter_inappwebview.callHandler('sign',rawTransaction).then(transactionID => transactionID)
    }
}''';
final oldSigningFunction =
    'oldSigningFunction = arweave.transactions.sign; alert("ArMob will manage message signing in this Dapp");';
final oddsigningFunction = '''arweave.transactions.sign = async function() {
   window.flutter_inappwebview.callHandler('sign',arguments).then(function(result) {
     if (confirm(`Transaction Fee \${arweave.ar.winstonToAr(arguments[0].reward)} AR. Do you want to sign this transaction?`)) {
    arguments[0].signature = result[0];
    arguments[0].id = result[1];
    console.log(arguments[0]);
    return arguments[0];  }
else { alert('Transaction canceled')}});
}''';
final signingFunction =
    '''arweave.transactions.sign = function() { walletAPI.sign(arguments).then(function(result) { console.log(result)})}''';

final unlockFunction =
    '''queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
          re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
          loginFunctionName = (queries[0].text.match(re))[0];''';

BigInt _base64ToInt(String encoded) {
  final b256 = new BigInt.from(256);
  encoded += new List.filled((4 - encoded.length % 4) % 4, "=").join();
  return base64Url
      .decode(encoded)
      .fold(BigInt.zero, (a, b) => a * b256 + new BigInt.from(b));
}

class WebViewContainer extends StatefulWidget {
  WebViewContainer({Key key}) : super(key: key);

  @override
  WebViewContainerState createState() => WebViewContainerState();
}

class WebViewContainerState extends State<WebViewContainer> {
  InAppWebViewController webViewController;
  double _progress = 0;
  static const platform = const MethodChannel('armob.dev/signer');

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Container(
          padding: EdgeInsets.all(2.0),
          child: _progress < 100
              ? LinearProgressIndicator(value: _progress)
              : Container()),
      Expanded(
          child: InAppWebView(
              initialUrl:
                  "https://alz4bdsrvmoz.arweave.net/fGUdNmXFmflBMGI2f9vD7KzsrAc1s1USQgQLgAVT0W0",
              initialHeaders: {},
              initialOptions: InAppWebViewWidgetOptions(
                  crossPlatform: InAppWebViewOptions(debuggingEnabled: true)),
              onWebViewCreated: (InAppWebViewController controller) {
                webViewController = controller;

                controller.addJavaScriptHandler(
                    handlerName: "address",
                    callback: (args) {
                      final _walletString =
                          Provider.of<WalletData>(context, listen: false)
                              .walletString;
                      var key = JsonWebKey.fromJson(jsonDecode(_walletString));
                      final publicKey = Map.from(
                          {'kty': key['kty'], 'e': key['e'], 'n': key['n']});
                      return jsonEncode(publicKey);
                    });
                controller.addJavaScriptHandler(
                    handlerName: "sign",
                    callback: (args) async {
                      final keyString =
                          Provider.of<WalletData>(context, listen: false)
                              .walletString;
                      Arweave.Wallet _myWallet =
                          Arweave.Wallet(jsonWebKey: keyString);
                      debugPrint('Hi ${args[0]['0'].toString()}',
                          wrapWidth: 1000);
                      debugPrint('Wallet key: ${_myWallet.address}');
                      List<int> transaction = _myWallet.createTransaction(
                          args[0]['0']['last_tx'], args[0]['0']['reward'],
                          data: Arweave.decodeBase64EncodedBytes(
                              args[0]['0']['data']),
                          tags: Arweave.decodeTags(args[0]['0']['tags']),
                          targetAddress: args[0]['0']['target'],
                          quantity: args[0]['0']['quantity']);

                      final signedTransaction =
                          await platform.invokeMethod('sign', {
                        'rawTransaction': Uint8List.fromList(transaction),
                        'n': _base64ToInt(_myWallet.jwk['n']).toString(),
                        'd': _base64ToInt(_myWallet.jwk['d']).toString(),
                        'dp': _base64ToInt(_myWallet.jwk['dp']).toString(),
                        'dq': _base64ToInt(_myWallet.jwk['dq']).toString()
                      });
                      final result = await _myWallet.postTransaction(
                          signedTransaction,
                          args[0]['0']['last_tx'],
                          args[0]['0']['reward'],
                          data: Arweave.decodeBase64EncodedBytes(
                              args[0]['0']['data']),
                          tags: Arweave.decodeTags(args[0]['0']['tags']),
                          targetAddress: args[0]['0']['target'],
                          quantity: args[0]['0']['quantity']);
                      debugPrint(
                          'Tx status - ${result[0].statusCode.toString()}');
                      return result[1];
                    });
              },
              onConsoleMessage: (InAppWebViewController controller, message) {
                debugPrint("Message from javascript - ${message.message}");
              },
              onProgressChanged:
                  (InAppWebViewController controller, int progress) {
                setState(() {
                  this._progress = progress / 100;
                });
              },
              onLoadStop: (InAppWebViewController controller, String status) {
                webViewController.evaluateJavascript(
                    source: oldSigningFunction);
                webViewController.evaluateJavascript(source: walletAPI);
                webViewController.evaluateJavascript(source: signingFunction);
              }))
    ]);
  }
}

class Browser extends StatefulWidget {
  const Browser({Key key}) : super(key: key);
  @override
  BrowserState createState() => BrowserState();
}

class BrowserState extends State<Browser> {
  String name;
/*
  void setUrl(String resolvedName) async {
    var trimmedName = resolvedName;
    if (resolvedName.contains('http://')) {
      trimmedName = resolvedName.substring(7);
    } else {
      if (resolvedName.contains('https://')) {
        trimmedName = resolvedName.substring(8);
      }
    }
    if (trimmedName.contains('/')) {
      webviewKey.currentState.webViewController
          .loadUrl(url: "https://" + trimmedName);
    } else {
      if (trimmedName.endsWith('.eth')) {
        try {
          final arTx = await resolve(nameHash(name));
          final url = 'https://arweave.net/' + arTx.toString();
          webviewKey.currentState.webViewController.loadUrl(url: url);
        } catch (__) {
          debugPrint("Name could not be resolved");
        }
      } else {
        webviewKey.currentState.webViewController
            .loadUrl(url: "https://" + trimmedName);
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final _walletString =
        Provider.of<WalletData>(context, listen: false).walletString;
    var key = JsonWebKey.fromJson(jsonDecode(_walletString));
    final publicKey =
        Map.from({'kty': key['kty'], 'e': key['e'], 'n': key['n']});
    final mes = jsonEncode(publicKey);
    final mes2 = jsonEncode(_walletString.toString());

    return Consumer<WalletData>(builder: (context, url, child) {
      return Scaffold(
        appBar: AppBar(
          title: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Address',
              ),
              onSubmitted: (value) {
                var url = value.toString();
                webviewKey.currentState.webViewController.loadUrl(url: url);
              }),
          backgroundColor: Color(0xFFFFFFFF),
        ),
        body: WebViewContainer(key: webviewKey),
        bottomNavigationBar: ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: "Back",
                onPressed: () =>
                    webviewKey.currentState.webViewController.goBack()),
            IconButton(
                icon: Icon(Icons.replay),
                tooltip: "Reload",
                onPressed: () =>
                    webviewKey.currentState.webViewController.reload()),
            IconButton(
                icon: Icon(Icons.lock_open),
                tooltip: "Unlock Wallet",
                onPressed: (_walletString != null)
                    ? () => webviewKey.currentState.webViewController
                        .evaluateJavascript(source: '''
                        var wallet = $mes;
                        var walletString = JSON.stringify(wallet);
                        walletString.replace(/"/g,"\\\"")
                        queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
                        re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
                        loginFunctionName = (queries[0].text.match(re))[0];
                        window[loginFunctionName]([new File([walletString],"wallet.json")]);''')
                    : null)
          ],
        ),
      );
    });
  }
}
