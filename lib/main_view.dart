import 'package:arweave/browser.dart';
import 'package:flutter/material.dart';

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
  const DestinationView({Key key, this.destination}) : super(key: key);

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
      text: 'sample text: ${widget.destination.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.destination.title) {
      case "Browser":
        return EnsName();
      case "Wallet":
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.destination.title} Text'),
          ),
          body: Container(
            padding: const EdgeInsets.all(32.0),
            alignment: Alignment.center,
            child: TextField(controller: _textController),
          ),
        );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
