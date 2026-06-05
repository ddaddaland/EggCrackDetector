import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/label/label.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector/processor/processor.dart';
import 'package:flutter/material.dart';

class ModelInspector extends StatefulWidget {
  final AbstractYoloModel model;

  const ModelInspector({
    required this.model,
    super.key,
  });

  @override
  State<ModelInspector> createState() => _ModelInspectorState();
}

class _ModelInspectorState extends State<ModelInspector> {
  late final model = widget.model;

  int? selectedClassIndex;

  final List<File> selectedImages = [];

  void pickImages() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '이미지 선택 (복수)',
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result == null) return;

    setState(() {
      selectedImages.addAll(result.paths.map((path) => File(path!)));
    });
  }

  void runInference() async {
    final processor = InferenceProcessor(
      model: model,
      imageFiles: selectedImages.toList(),
      option: InferenceOption(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // classes
        LightBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Label(Icons.data_object, '클래스'),
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 10,
                    children: [
                      ...model.classes.indexed.map((pair) {
                        final index = pair.$1;
                        final cls = pair.$2;
                        return LightBox(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Row(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('$index'),
                              Text('${cls.label}'),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              selectedClassIndex = index;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        //
        Expanded(
          child: LightBox(
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Label(Icons.image, '추론'),
                Expanded(
                  child: LightBox(
                    child: Builder(
                      builder: (context) {
                        if (selectedImages.isEmpty) {
                          return Center(
                            child: Text('이미지를 선택해주세요'),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                            childAspectRatio: 1,
                          ),
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) {
                            final image = selectedImages[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(image, fit: BoxFit.cover),
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    child: Text('${(image.lengthSync() / (1024 * 1024)).toStringAsFixed(2)}MB'),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    spacing: 5,
                    children: [
                      LightBox(
                        width: 120,
                        child: Center(child: Text('초기화')),
                        onTap: selectedImages.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  selectedImages.clear();
                                });
                              },
                      ),
                      LightBox(
                        width: 220,
                        child: Center(child: Text('이미지 선택')),
                        onTap: pickImages,
                      ),
                      Expanded(
                        child: LightBox(
                          child: Center(child: Text('추론 (${selectedImages.length})')),
                          onTap: selectedImages.isEmpty ? null : () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
