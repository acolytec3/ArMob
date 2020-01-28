import 'package:flutter/material.dart';
import 'main_view.dart';

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

  launchBrowser(int index, String url) {
    _currentIndex = index;
    _url = url;
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
                child: IndexedStack(
                  index: _currentIndex,
                  children:
                      allDestinations.map<Widget>((Destination destination) {
                    return DestinationView(
                        destination: destination,
                        notifyParent: launchBrowser,
                        url: _url);
                  }).toList(),
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
