import 'dart:convert';
import 'package:arweave/ens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';
import 'package:arweave/appState.dart';
import 'dart:async';

var loginFunction;

final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.toString());
      }),
].toSet();

//Future Javascript awesomeness
final cache =
    'cache = arweave.transactions.sign; alert("ArMob will manage message signing in this Dapp");';
final signingFunction = '''arweave.transactions.sign = async function() {
if (confirm(`Transaction Fee \${arweave.ar.winstonToAr(arguments[0].reward)} AR. Do you want to sign this transaction?`)) {
result = await cache.apply(this, arguments);
return result;
}
else { alert('Transaction canceled')}}''';

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
  double _progress;

  final flutterWebViewPlugin = FlutterWebviewPlugin();

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

  StreamSubscription<double> _onProgressChanged;

  StreamSubscription<WebViewStateChanged> _onStateChanged;

  @override
  void initState() {
    super.initState();

    flutterWebViewPlugin.close();

    _onProgressChanged =
        flutterWebViewPlugin.onProgressChanged.listen((double progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
        });
        if (progress >= 99) {}
      }
    });

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (state.type == WebViewState.finishLoad) {
        flutterWebViewPlugin.evalJavascript(cache);
        flutterWebViewPlugin.evalJavascript(signingFunction);
      }
    });
  }

  @override
  void dispose() {
    _onProgressChanged.cancel();

    flutterWebViewPlugin.dispose();

    super.dispose();
  }

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
          javascriptChannels: jsChannels,
          url:
              "https://ftesrg4ur46h.arweave.net/nej78d0EJaSHwhxv0HAZkTGk0Dmc15sChUYfAC48QHI/index.html",
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
          queries = (Array.from(document.getElementsByTagName('script'))).filter(script => script.text.includes("new FileReader"));
          re = /(?<=function\\s+)(\\w+)(?=\\s*\\(\\w*\\)\\s*\\{[\\s\\S]+new FileReader[\\s\\S]*})/;
          loginFunctionName = (queries[0].text.match(re))[0];
          window[loginFunctionName]([new File([walletString.toString()],"wallet.json")])''')
                      : null)
            ],
          ),
        );
      }),
    );
  }
}
