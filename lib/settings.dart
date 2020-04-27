import 'package:libarweave/libarweave.dart' as Ar;
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _settingsState createState() => _settingsState();
}

class _settingsState extends State<Settings> {
  String _gateway = "https://arweave.net:443";
  String _customGateway = '';

  @override
  Widget build(BuildContext context) {
    return (Column(
      children: [
        Text(
          "Gateway",
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.justify,
        ),
        RadioListTile(
            value: 'https://arweave.net:443',
            title: Text("Arweave.net"),
            groupValue: _gateway,
            onChanged: ((value) {
              _gateway = value;
              Ar.setPeer(peerAddress: _gateway);
              setState(() {});
            })),
        RadioListTile(
            value: 'https://perma.online:443',
            title: Text("Perma.online"),
            groupValue: _gateway,
            onChanged: ((value) {
              _gateway = value;
              Ar.setPeer(peerAddress: _gateway);
              setState(() {});
            })),
        ListTile(
            leading: Radio(
                value: _customGateway,
                groupValue: _gateway,
                onChanged: ((String value) {
                  if (_customGateway != '') {
                    _gateway = _customGateway;
                  }

                  Ar.setPeer(peerAddress: _gateway);
                  setState(() {});
                })),
            title: TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Custom Gateway",
                  hintText:"http://myCustomGateway:1854"),
              onChanged: (value) => _customGateway = value,
            ))
      ],
    ));
  }
}
