import 'package:fire_egg_detector/camera/camera.dart';
import 'package:fire_egg_detector/detector/option/server_option.dart';
import 'package:fire_egg_detector/lift/lift.dart';
import 'package:fire_egg_detector/model/model.dart';

class DetectorInstanceOption {
  String? id;
  String? appVersion;
  AbstractYoloModel? model;
  ServerOption? serverOption;
  AbstractLift? lift;
  final List<AbstractCamera> cameras = [];

  void ensureValid() {
    if (id == null || id!.isEmpty) throw ArgumentError('id is required');
    if (appVersion == null || appVersion!.isEmpty) throw ArgumentError('appVersion is required');
    if (model == null) throw ArgumentError('model is required');
    if (serverOption == null) throw ArgumentError('serverOption is required');
    if (lift == null) throw ArgumentError('lift is required');
    if (cameras == null || cameras!.isEmpty) throw ArgumentError('at least one camera is required');
  }
}
