import 'package:arweave/browser.dart';
import 'package:flutter/material.dart';
import 'package:arweave/wallet.dart';
import 'package:arweave/appState.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:arweave/settings.dart';

void main() {
  runApp(ChangeNotifierProvider(
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
  launchBrowser(int index, String url) {
    _currentIndex = index;
    setState(() {});
    webviewKey.currentState.webViewController.loadUrl(url: url);
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
        title: 'ArMob',
        home: Scaffold(
            appBar: AppBar(title: Text(((Provider.of<WalletData>(context, listen: true).arweaveId) != null) ? Provider.of<WalletData>(context, listen: true).arweaveId : 'Wallet'), actions: <Widget>[
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Padding(child: Text(Provider.of<WalletData>(context, listen: true)
                        .walletBalance
                        .toStringAsFixed(6) +
                    " AR"), padding: const EdgeInsets.all(10.0)),
              ])
            ]),
            body: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Offstage(
                        offstage: _currentIndex != 0,
                        child: Wallet(notifyParent: launchBrowser)),
                    Offstage(
                      offstage: _currentIndex != 1,
                      child: Browser(),
                    ),
                    Offstage(child: Settings(), offstage: _currentIndex != 2)
                  ],
                )),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });},
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.attach_money),
                    title: Text("Wallet"),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    title: Text("Browser"),
                  ),
                  BottomNavigationBarItem(icon: Icon(Icons.settings),title: Text("Settings"))
                ])));
  }
}
