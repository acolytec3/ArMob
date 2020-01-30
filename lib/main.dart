import 'package:arweave/browser.dart';
import 'package:flutter/material.dart';
//import 'package:arweave/wallet.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _url;

  launchBrowser(int index) {
    _currentIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Arwen Browser',
        home: Scaffold(
            appBar: AppBar(
              title: Text("Arwen"),
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
                      child: EnsName(url: _url),
                    )
                  ],
                )),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    title: Text("Wallet"),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.developer_mode),
                    title: Text("Browser"),
                  ),
                ])));
  }
}
