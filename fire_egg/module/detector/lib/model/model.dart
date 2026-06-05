import 'dart:typed_data';

import 'package:fire_egg_detector/config/image_size.dart';
import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_common/detection/object_class.dart';

abstract class AbstractYoloModel {
  final String name, description;
  final int imageSize;
  final String? parentModel;
  final List<YoloObjectClass> classes;


  AbstractYoloModel({
    this.imageSize = DetectorImageSize.defaultSize,
    required this.name,
    required this.parentModel,
    required this.classes,
    required this.description,
  });

  bool get isCloud;

  bool get isLoaded;

  Future<bool> load();

  Future<void> unLoad();

  Future<List<Detection>> detect(Uint8List bytes, InferenceOption option);
}
