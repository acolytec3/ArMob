import 'package:arweave/browser.dart';
import 'package:flutter/material.dart';
import 'package:arweave/wallet.dart';
import 'package:arweave/appState.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:io';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WalletData(),
      child: HomePage(),
    ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  File wallet;
  
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  launchBrowser(int index, String url) {
    _currentIndex = index;
    setState(() {});
    flutterWebViewPlugin.reloadUrl(url);
    flutterWebViewPlugin.show();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'ArMob',
        home: Scaffold(
            appBar: AppBar(
              title: Text("ArMob"),
            ),
            body: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Offstage(
                        offstage: _currentIndex != 0,
                        child: Wallet(notifyParent: launchBrowser)),
                    Offstage(
                      offstage: _currentIndex != 1,
                      child: EnsName(),
                    )
                  ],
                )),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (_currentIndex == 0){
                    flutterWebViewPlugin.hide();
                  }
                  else flutterWebViewPlugin.show();
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.attach_money),
                    title: Text("Wallet"),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    title: Text("Browser"),
                  ),
                ])));
  }
}
