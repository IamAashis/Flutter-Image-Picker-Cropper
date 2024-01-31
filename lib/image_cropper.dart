import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class MyImagePicker extends StatefulWidget {
  @override
  _MyImagePickerState createState() => _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  XFile? imageFile; // Nullable File

  Future<void> _getImage(int type) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: type == 1 ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        const cropAspectRatio = CropAspectRatio(ratioX: 1.0, ratioY: 1.0);

        final cropper = ImageCropper();
        final croppedFile = await cropper.cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: cropAspectRatio,
          maxWidth: 700,
          maxHeight: 700,
        );

        if (croppedFile != null) {
          final cacheDirectory = path.dirname(pickedFile.path);
          final compressedFileName =
              'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final compressedFilePath =
              path.join(cacheDirectory, compressedFileName);

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            croppedFile.path,
            compressedFilePath,
            quality: 100,
          );

          if (compressedFile != null) {
            setState(() {
              imageFile = compressedFile;
            });
          } else {
            print('Compression failed: Result is null');
          }
        }
      }
    } catch (e) {
      if (e is CompressError) {
        print('CompressError details: ${e.message}');
      } else {
        print('CompressError details: compression: $e');
      }
    }
  }

  Future<bool> _hasCameraPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return true;
    } else {
      return true;
    }
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Picker"),
          content: Text("Select image picker type."),
          actions: <Widget>[
            _buildTextButton("Camera", () {
              _getImage(1);
              Navigator.pop(context);
            }),
            _buildTextButton("Gallery", () {
              _getImage(2);
              Navigator.pop(context);
            }),
          ],
        );
      },
    );
  }

  TextButton _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Picker"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildImageOrPlaceholder(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentContext = context;

          if (await _hasCameraPermission()) {
            _showImagePickerDialog(currentContext);
          } else {
            print("Camera permission not granted!");
          }
        },
        tooltip: 'Pick Image',
        child: const Icon(Icons.camera),
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    return imageFile != null
        ? Image.file(
            File(imageFile!.path),
            height: MediaQuery.of(context).size.height / 2,
          )
        : Text("Image editor");
  }
}
