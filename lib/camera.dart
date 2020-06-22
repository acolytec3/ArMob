import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arweave/transaction.dart';
import 'package:libarweave/libarweave.dart' as Ar;

class CameraApp extends StatefulWidget {
  final Ar.Wallet wallet;

    const CameraApp({Key key, this.wallet})
      : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController controller;
  List cameras;
  int selectedCameraIdx;
  String imagePath;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIdx = 0;
        });

        _initCameraController(cameras[selectedCameraIdx]).then((void v) {});
      } else {
        print("No camera available");
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print('Error $e on initializing camera');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onSwitchCamera() {
    selectedCameraIdx =
        selectedCameraIdx < cameras.length - 1 ? selectedCameraIdx + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera);
  }

  _onTakePicture() async {
      try {
    
    final path = '${(await getTemporaryDirectory()).path}${DateTime.now()}.png';
    
    await controller.takePicture(path);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _previewImage(path),
      ),
    );
  } catch (e) {
    print(e);
  }

  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  Widget _previewImage(String imagepath){
    return Stack(
          children: [Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                
                image: FileImage(File(imagepath)),
                fit: BoxFit.cover))),
                      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
                heroTag: null,
                elevation: 2,
                onPressed: (){
                  Navigator.pop(context);
                },
                tooltip: "Back",
                child: Icon(Icons.refresh)),
          ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
              heroTag: null,
              elevation: 2,
              onPressed: () {
                Route route = MaterialPageRoute(
                              builder: (context) => Transaction(
                                  wallet: widget.wallet, transactionType: imagepath));
                          Navigator.pushReplacement(context, route);
              },
              tooltip: "Upload Picture",
              child: Icon(Icons.cloud_upload)),
        )),]
    );
  }
  @override
  void dispose() {
    controller?.dispose();
    Navigator.pop(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return _cameraPreviewWidget();
    }
    return Stack(children: <Widget>[
      AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller)),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
                heroTag: null,
                elevation: 2,
                onPressed: _onSwitchCamera,
                tooltip: "Switch Camera",
                child: Icon(Icons.switch_camera)),
          ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
              heroTag: null,
              elevation: 2,
              onPressed: _onTakePicture,
              tooltip: "Take Picture",
              child: Icon(Icons.adjust)),
        ),
      )
    ]);
  }
}
