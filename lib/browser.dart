import 'dart:convert';
import 'package:arweave/ens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';

var loginFunction;

final webviewKey = GlobalKey<WebViewContainerState>();


final cache =
    'cache = arweave.transactions.sign; alert("ArMob will manage message signing in this Dapp");';
final signingFunction = '''arweave.transactions.sign = async function() {
if (confirm(`Transaction Fee \${arweave.ar.winstonToAr(arguments[0].reward)} AR. Do you want to sign this transaction?`)) {
result = await cache.apply(this, arguments);
return result;
}
else { alert('Transaction canceled')}}''';

class WebViewContainer extends StatefulWidget {
  WebViewContainer({Key key}) : super(key: key);

  @override
  WebViewContainerState createState() => WebViewContainerState();
}

class WebViewContainerState extends State<WebViewContainer> {
  InAppWebViewController webViewController;
  double _progress = 0;
 @override
  Widget build(BuildContext context) {
    final _walletString =
        Provider.of<WalletData>(context, listen: false).walletString;
    return InAppWebView(
                  initialUrl: "https://ftesrg4ur46h.arweave.net/nej78d0EJaSHwhxv0HAZkTGk0Dmc15sChUYfAC48QHI/index.html",
                  initialHeaders: {},
                  initialOptions: InAppWebViewWidgetOptions(
                  ),
                  onWebViewCreated: (InAppWebViewController controller) {
                    webViewController = controller;
                  },
                  onProgressChanged: (InAppWebViewController controller, int progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onLoadStop: (InAppWebViewController controller, String status) {
                            webViewController.evaluateJavascript(source: cache);
                            webViewController.evaluateJavascript(source: signingFunction);
                  });
  }
}
class Browser extends StatefulWidget {
  const Browser({Key key}) : super(key: key);
  @override
  BrowserState createState() => BrowserState();
}

class BrowserState extends State<Browser> {
  String name;
  double _progress = 0;

  //TODO - Make this a global key somehow

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
      webviewKey.currentState.webViewController.loadUrl(url: "https://" + trimmedName);
    } else {
      if (trimmedName.endsWith('.eth')) {
        try {
          final arTx = await resolve(nameHash(name));
          final url = 'https://arweave.net/' + arTx.toString();
          webviewKey.currentState.webViewController.loadUrl(url: url);
        } catch (__) {
          print("Name could not be resolved");
        }
      } else {
        webviewKey.currentState.webViewController.loadUrl(url: "https://" + trimmedName);
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    final _walletString =
        Provider.of<WalletData>(context, listen: false).walletString;
    final mes = jsonEncode(_walletString).toString();
    return Consumer<WalletData>(builder: (context, url, child) {
        return Scaffold(
          appBar: AppBar(
              title: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Address',
                  ),
                  onSubmitted: (value) {
                    setUrl(value);
                  }),
              backgroundColor: Color(0xFFFFFFFF),
              bottom: PreferredSize(
                  preferredSize: Size(double.infinity, 1.0),
                  child: (LinearProgressIndicator(value: _progress)))),
              body: Container(child: Column(children: <Widget>[
                Container(
                padding: EdgeInsets.all(10.0),
                child: _progress < 1.0
                    ? LinearProgressIndicator(value: _progress)
                    : Container()),
                Expanded(
              child: Container(
                margin: const EdgeInsets.all(10.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                child: WebViewContainer(key: webviewKey)))
              ],)),         
          bottomNavigationBar: ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  tooltip: "Back",
                  onPressed: () => webviewKey.currentState.webViewController.goBack()),
              IconButton(
                  icon: Icon(Icons.replay),
                  tooltip: "Reload",
                  onPressed: () => webviewKey.currentState.webViewController.reload()),
              IconButton(
                  icon: Icon(Icons.lock_open),
                  tooltip: "Unlock Wallet",
                  onPressed: (_walletString != null)
                     ? () => webviewKey.currentState.webViewController.evaluateJavascript(source: '''
          var walletString = $mes;
          queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
          re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
          loginFunctionName = (queries[0].text.match(re))[0];
          window[loginFunctionName]([new File([walletString.toString()],"wallet.json")])''')
                      : null)
            ],
          ),
        );
      });
  }
}
