import 'package:fire_egg_detector/camera/sample.dart';
import 'package:fire_egg_detector/camera/usb.dart';
import 'package:fire_egg_detector/config/image_size.dart';
import 'package:fire_egg_detector/detector/option/option.dart';
import 'package:fire_egg_detector/detector/option/server_option.dart';
import 'package:fire_egg_detector/lift/sample.dart';
import 'package:fire_egg_detector_gui/lift/serial.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector_gui/camera/preview.dart';
import 'package:fire_egg_detector_gui/detector/server_option_creator.dart';
import 'package:fire_egg_detector_gui/lift/preview.dart';
import 'package:fire_egg_detector_gui/model/tile.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:image/image.dart' as img;

class DetectorInstanceOptionBuilder extends StatefulWidget {
  final DetectorInstanceOption option;
  final int imageSize;
  final List<AbstractYoloModel> models;
  final void Function() onChanged;

  const DetectorInstanceOptionBuilder({
    super.key,
    required this.option,
    required this.imageSize,
    required this.models,
    required this.onChanged,
  });

  @override
  State<DetectorInstanceOptionBuilder> createState() => _DetectorInstanceOptionBuilderState();
}

class _DetectorInstanceOptionBuilderState extends State<DetectorInstanceOptionBuilder> {
  late final option = widget.option;
  static const _sampleAssetIndexes = ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'];

  int lastCameraIndex = 0;

  void onChanged() {
    widget.onChanged();
  }

  Future<Uint8List> _loadSampleFrame(String index) async {
    // Keep 1280 assets as the source set and scale down for 640 when needed.
    final data = await rootBundle.load('asset/cam_sample/1280_$index.jpg');
    if (widget.imageSize == DetectorImageSize.size1280) {
      return data.buffer.asUint8List();
    }

    final original = img.decodeImage(data.buffer.asUint8List());
    if (original == null) {
      throw StateError('샘플 이미지를 디코딩할 수 없습니다.');
    }
    final resized = img.copyResize(original, width: widget.imageSize, height: widget.imageSize);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // basic
        LightBox.label(
          label: '검출기 ID',
          icon: Icons.tag,
          child: TextField(
            controller: TextEditingController(
              text: option.id,
            ),
            onChanged: (value) {
              option.id = value;
              onChanged();
            },
          ),
        ),

        // version
        LightBox.label(
          label: '앱 버전',
          icon: Icons.info_outline,
          child: TextField(
            controller: TextEditingController(
              text: option.appVersion,
            ),
            onChanged: (value) {
              option.appVersion = value;
              onChanged();
            },
          ),
        ),

        // inference
        LightBox.label(
          label: '추론 모델',
          icon: Icons.model_training_outlined,
          trailing: IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final selected = await showDialog<AbstractYoloModel>(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text('모델 선택'),
                    contentPadding: EdgeInsets.all(25),
                    children: [
                      ...widget.models.map((model) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: LightBox(
                            child: ModelTile(model: model),
                            onTap: () {
                              Navigator.pop(context, model);
                            },
                          ),
                        );
                      }),
                    ],
                  );
                },
              );

              if (selected is AbstractYoloModel) {
                setState(() {
                  option.model = selected;
                });
                onChanged();
              }
            },
          ),
          child: LightBox(
            child: option.model == null
                ? Text('선택되지 않음')
                : ModelTile(
                    model: option.model!,
                  ),
          ),
        ),

        // lift
        LightBox.label(
          label: '리프트',
          icon: Icons.vertical_align_top,
          trailing: Row(
            children: [
              IconButton(
                icon: Icon(Icons.code),
                tooltip: '샘플 리프트 추가',
                onPressed: () {
                  setState(() {
                    option.lift = SampleLift(interval: Duration(seconds: 5));
                  });
                  onChanged();
                },
              ),
              IconButton(
                icon: Icon(Icons.usb),
                tooltip: '시리얼 리프트 설정',
                onPressed: () async {
                  final portController = TextEditingController(
                    text: (option.lift is SerialLift) ? (option.lift as SerialLift).portName : '/dev/ttyACM0',
                  );
                  final baudController = TextEditingController(
                    text: (option.lift is SerialLift) ? (option.lift as SerialLift).baudRate.toString() : '9600',
                  );

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('시리얼 리프트 설정'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: portController,
                            decoration: InputDecoration(labelText: '포트 (예: /dev/ttyACM0 또는 /dev/ttyUSB0)'),
                          ),
                          Text('${SerialPort.availablePorts.join('\n')}'),
                          SizedBox(height: 8),
                          TextField(
                            controller: baudController,
                            decoration: InputDecoration(labelText: 'Baud Rate (예: 9600)'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('적용')),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final baud = int.tryParse(baudController.text) ?? 9600;
                    setState(() {
                      option.lift = SerialLift(
                        portName: portController.text.trim(),
                        baudRate: baud,
                      );
                    });
                    onChanged();
                  }
                },
              ),
            ],
          ),
          child: LightBox(
            child: option.lift == null
                ? Center(child: Text('선택되지 않음'))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.vertical_align_top),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${option.lift!.runtimeType}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${option.lift!.description}',
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      LightBox(
                        padding: EdgeInsets.all(10),
                        child: LiftPreview(lift: option.lift!),
                      ),
                    ],
                  ),
          ),
        ),

        // camera
        if (option.model != null)
          LightBox.label(
            label: '카메라',
            icon: Icons.camera_alt_outlined,
            trailing: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.code),
                  tooltip: '샘플 카메라 추가',
                  onPressed: () {
                    setState(() {
                      option.cameras.add(
                        SampleCamera(
                          imageSize: widget.imageSize,
                          providers: _sampleAssetIndexes
                              .map(
                                (index) =>
                                    () => _loadSampleFrame(index),
                              )
                              .toList(),
                        ),
                      );
                    });
                    onChanged();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  tooltip: 'USB 카메라 추가',
                  onPressed: () {
                    setState(() {
                      option.cameras.add(
                        UsbCamera(deviceName: '/dev/video${lastCameraIndex}', quality: 65),
                      );
                    });
                    lastCameraIndex++;
                    onChanged();
                  },
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                if (option.cameras.isEmpty) {
                  return LightBox(child: Center(child: Text('추가되지 않음')));
                }

                return Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...option.cameras.map(
                      (cam) => LightBox(
                        child: Row(
                          spacing: 10,
                          children: [
                            Expanded(
                              child: Row(
                                spacing: 10,
                                children: [
                                  Icon(Icons.camera_alt),
                                  Text(
                                    '${cam.runtimeType}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: CameraPreview(
                                camera: cam,
                                imageSize: option.model!.imageSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // server
        LightBox.label(
          label: '서버',
          icon: Icons.cloud,
          trailing: IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final option = await showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    constraints: BoxConstraints(
                      maxWidth: 500,
                    ),
                    child: AnimatedSize(
                      duration: Durations.short4,
                      curve: Curves.easeOutQuart,
                      child: DetectorServerOptionCreator(
                        initialPassword: 'password',
                        onCreate: (opt) => Navigator.pop(context, opt),
                      ),
                    ),
                  ),
                ),
              );

              if (option is! ServerOption) return;

              setState(() {
                this.option.serverOption = option;
              });
              onChanged();
            },
          ),
          child: LightBox(
            child: Center(
              child: option.serverOption == null
                  ? Text('설정되지 않음')
                  : Text(
                      '${option.serverOption!.displayName} (${option.serverOption!.address})',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
