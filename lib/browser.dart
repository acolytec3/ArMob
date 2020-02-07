import 'dart:convert';
import 'package:arweave/ens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';

var loginFunction;

Future<bool> _exitApp(BuildContext context) async {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  if (await flutterWebViewPlugin.canGoBack()) {
    flutterWebViewPlugin.goBack();
    return Future.value(false);
  } else {
    Scaffold.of(context)
        .showSnackBar(const SnackBar(content: Text("No page to go back to")));
    return Future.value(false);
  }
}

class EnsName extends StatefulWidget {
  const EnsName({Key key}) : super(key: key);
  @override
  EnsNameState createState() => EnsNameState();
}

class EnsNameState extends State<EnsName> {
  String name;

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
      flutterWebViewPlugin.reloadUrl("https://" + trimmedName);
    } else {
      if (trimmedName.endsWith('.eth')) {
        try {
          final arTx = await resolve(nameHash(name));
          final url = 'https://arweave.net/' + arTx.toString();
          flutterWebViewPlugin.reloadUrl(url);
        } catch (__) {
          print("Name could not be resolved");
        }
      } else {
        flutterWebViewPlugin.reloadUrl("https://" + trimmedName);
      }
    }
  }

  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    final _walletString =
        Provider.of<WalletData>(context, listen: false).walletString;
    final mes = jsonEncode(_walletString).toString();
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Consumer<WalletData>(builder: (context, url, child) {
        return WebviewScaffold(
          appBar: AppBar(
            title:TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Address',
                ),
                onSubmitted: (value) {
                  setUrl(value);
                }),
                backgroundColor: Color(0xFFFFFFFF),),
          javascriptChannels: <JavascriptChannel>[
            JavascriptChannel(
                name: '_print',
                onMessageReceived: (JavascriptMessage msg) {
                  loginFunction = msg.message;
                }),
          ].toSet(),
          url: "https://ftesrg4ur46h.arweave.net/nej78d0EJaSHwhxv0HAZkTGk0Dmc15sChUYfAC48QHI/index.html",
          bottomNavigationBar: ButtonBar(
            alignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.arrow_back),
                  tooltip: "Back",
                  onPressed: () => flutterWebViewPlugin.goBack()),
              IconButton(
                  icon: Icon(Icons.replay),
                  tooltip: "Reload",
                  onPressed: () => flutterWebViewPlugin.reload()),
              IconButton(
                  icon: Icon(Icons.lock_open),
                  tooltip: "Unlock Wallet",
                  onPressed: (_walletString != null)
                      ? () => flutterWebViewPlugin.evalJavascript('''
          var walletString = $mes;
          console.log(walletString);
          queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
          re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
          loginFunctionName = (queries[0].text.match(re))[0];
          window._print.postMessage(loginFunctionName);
          window[loginFunctionName]([new File([walletString.toString()],"wallet.json")])''')
                      : null)
            ],
          ),
        );
      }),
    );
  }
}
