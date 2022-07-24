import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:tflite/tflite.dart';

class Classifier extends StatefulWidget {
  const Classifier({Key? key}) : super(key: key);

  @override
  State<Classifier> createState() => _ClassifierState();
}

class _ClassifierState extends State<Classifier> {
  List? _outputs;
  File? _image;
  bool _loading = false;
  String? url;
  late File selectedImage;
  late File selectedImagee;
  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }
  final ImagePicker _picker = ImagePicker();
  final controllerr = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controllerr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _loading
            ? Container(
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        )
            : Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image == null ? Container(
                  child: Lottie.asset('assets/3.json'),
                ) : result1(),
                _image == null ? Container() : Padding(
                  padding: const EdgeInsets.only(
                      top: 30
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed: () async {
                      final imageee = await controllerr.captureFromWidget(result1());
                      if (imageee == null)
                        return ;
                      await save(imageee);
                    },
                    child: const Text(
                      'save result to the Gallery',
                      style: TextStyle(
                          fontSize: 22
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _image == null ? Container() : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  onPressed: (){
                    //  upload to fire store function
                  },
                  child: const Text(
                    'save result to the Cloud',
                    style: TextStyle(
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _image == null ? Container() : const Text(
                  ' Warning: this result may not accurate so you need to consulting a doctor as soon as possible(The accuracy of the results is 91%)',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: pickImage,
          child: const Icon(Icons.image),
        ),
      ),
    );
  }

  Future pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = selectedImage = File(image.path);
    });
    classifyImage(File(image.path));
  } // to get image from gallery

  Future<String>  save(Uint8List bytes) async {
    await [Permission.storage].request();
    final name = 'result of Xray';
    final result = await ImageGallerySaver.saveImage(bytes , name : name);
    return result['filepath'];
  } // to save the result to gallery

  Widget result1() => Container(
    color: Colors.white,
    child: Stack(

      children: [
        Image.file(_image!),
        const SizedBox(
          height: 30,
        ),
        _outputs == null ? Container() : Positioned(
          bottom:0,
          right: 50,
          child: Text(
            "${_outputs![0]["label"]}",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.0,
              background: Paint()..color = Colors.white,
            ),
          ),
        ),
        const SizedBox(
          height: 30,
        )
      ],
    ),
  );

  Future classifyImage( File image ) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 1,
        threshold: 0.2,
        imageMean: 0.0,
        imageStd: 180.0,
        asynch: true
    );
    setState(() {
      _loading = false;
      _outputs = output!;
    });
  } // to classify the image and return the output

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",

    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}



