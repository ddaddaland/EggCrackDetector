import 'package:json_annotation/json_annotation.dart';
import 'package:fire_egg_common/core/rect.dart';

part 'crack_data.g.dart';

/// 개별 크랙 정보 모델
/// 계란에서 검출된 단일 크랙의 바운딩 박스와 신뢰도 정보를 포함합니다.
@JsonSerializable()
class CrackData {
  /// 크랙 바운딩 박스 좌표
  final Rect box;

  /// 크랙 검출 확신도 (0.0 ~ 1.0)
  final double confidence;
  final int shotIndex;

  CrackData({
    required this.shotIndex,
    required this.box,
    required this.confidence,
  });

  /// 크랙의 중심점(cx, cy)을 반환합니다.
  /// 중심점은 거리 계산 매칭에 사용됩니다.
  List<double> getCenter() {
    final cx = (box.left + box.right) / 2;
    final cy = (box.top + box.bottom) / 2;
    return [cx, cy];
  }

  factory CrackData.fromJson(Map<String, dynamic> json) => _$CrackDataFromJson(json);

  Map<String, dynamic> toJson() => _$CrackDataToJson(this);
}
