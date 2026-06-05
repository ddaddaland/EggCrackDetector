import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:flutter/material.dart';

class ModelTile extends StatelessWidget {
  final AbstractYoloModel model;

  const ModelTile({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(
              model.isCloud ? Icons.cloud : Icons.memory,
              color: Theme.of(context).colorScheme.primary,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${model.parentModel} / ${model.imageSize} x ${model.imageSize} / ${model.description}',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        Divider(),
        Row(
          spacing: 10,
          children: [
            ...model.classes.indexed.map((pair) {
              final index = pair.$1;
              final cls = pair.$2;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(cls.color).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(cls.color).withAlpha(90),
                  ),
                ),
                child: Row(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('($index) ${cls.label}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
