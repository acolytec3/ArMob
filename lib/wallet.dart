
import 'package:flutter/material.dart';

class Wallet extends StatefulWidget {
  @override
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> {
  String name;
  Future<String> url;

  @override
  Widget build(BuildContext context) {
    return Text('This will be a wallet');
  }
}