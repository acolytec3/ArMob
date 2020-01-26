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
                    return DestinationView(destination: destination);
                  }).toList(),
                )),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: allDestinations.map((Destination destination) {
                return BottomNavigationBarItem(
                    icon: Icon(destination.icon),
                    title: Text(destination.title));
              }).toList(),
            )));
  }
}
