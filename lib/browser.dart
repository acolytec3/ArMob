import 'dart:convert';
import 'package:arweave/ens.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';

final webViewKey = GlobalKey<WebViewContainerState>();

var loginFunction;

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
    try {
      final arTx = await resolve(nameHash(name));
      url = 'https://arweave.net/' + arTx.toString();
      webViewKey.currentState?.loadURL(url);
    } catch (__) {
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
        ButtonBar(
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.replay),
                tooltip: "Reload",
                onPressed: () => webViewKey.currentState?.reload()),
            IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: "Back",
                onPressed: () => webViewKey.currentState?.goBack()),
            IconButton(
                icon: Icon(Icons.lock_open),
                tooltip: "Unlock Wallet",
                onPressed: () =>
                    webViewKey.currentState?.callLoginFunction(loginFunction)),
          ],
        )
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
    final _walletString = Provider.of<walletData>(context, listen: false).walletString;
    return WebView(
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      initialUrl:
          "https://ftesrg4ur46h.arweave.net/nej78d0EJaSHwhxv0HAZkTGk0Dmc15sChUYfAC48QHI/index.html",
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: <JavascriptChannel>[
        JavascriptChannel(
            name: '_print',
            onMessageReceived: (JavascriptMessage msg) {
              loginFunction = msg.message;
            }),
      ].toSet(),
      onPageFinished: (url) {
        final mes = jsonEncode(_walletString).toString();
        final findLoginFunction = '''
          var walletString = $mes;
          queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
          re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
          loginFunctionName = (queries[0].text.match(re))[0];
          window._print.postMessage(loginFunctionName);''';
        _webViewController.evaluateJavascript(findLoginFunction);
      },
    );
  }

  void loadURL(String url) {
    _webViewController?.loadUrl(url);
  }

  void callLoginFunction(String code) {
    _webViewController?.evaluateJavascript(
        'window[loginFunctionName]([new File([walletString.toString()],"wallet.json")])');
  }

  void goBack() {
    _webViewController?.goBack();
  }

  void reload() {
    _webViewController?.reload();
  }
}

