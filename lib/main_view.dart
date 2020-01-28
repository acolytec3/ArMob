import 'package:arweave/browser.dart';
import 'package:flutter/material.dart';
import 'package:arweave/wallet.dart';

class Destination {
  const Destination(this.title, this.icon);
  final String title;
  final IconData icon;
}

const List<Destination> allDestinations = <Destination>[
  Destination('Wallet', Icons.home),
  Destination('Browser', Icons.business),
];

class DestinationView extends StatefulWidget {
  final String url;
  final Function(int index, String url) notifyParent;
  const DestinationView({Key key, this.destination, @required this.notifyParent, this.url}) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: '${widget.destination.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.destination.title) {
      case "Browser":
        return EnsName(url: widget.url);
      case "Wallet":
        return Wallet(
          notifyParent: widget.notifyParent,
        );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
