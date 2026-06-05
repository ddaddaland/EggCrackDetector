import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/detector/message.dart';
import 'package:fire_egg_common/detector/state.dart';
import 'package:fire_egg_common/capture/result.dart';
import 'package:fire_egg_common/egg/crack_data.dart';
import 'package:fire_egg_common/egg/egg.dart';
import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_common/episode/shot.dart';
import 'package:fire_egg_common/lift/signal.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_detector/camera/camera.dart';
import 'package:fire_egg_detector/detector/camera_images.dart';
import 'package:fire_egg_detector/detector/option/server_option.dart';
import 'package:fire_egg_detector/lift/lift.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:http/http.dart' as http;

class DetectorInstance {
  final String id;
  final AbstractYoloModel model;
  final String appVersion;

  late final int imageSize = model.imageSize;
  late final logger = Logger('${id}');

  DetectorState _currentState = DetectorState.idle;

  // message
  int _totalMessagesCount = 0, _currentMessagesCount = 0;
  final List<DetectorMessage> messages = [];
  final _messageStreamController = StreamController<DetectorMessage>.broadcast();
  late final messageStream = _messageStreamController.stream;

  // camera
  final List<AbstractCamera> cameras;
  final List<StreamSubscription> _cameraSubscriptions = [];

  // lift
  final AbstractLift lift;
  StreamSubscription? _liftSignalSubscription;

  // inference
  final eggClasses = {0};
  final crackClasses = {1};
  final inferenceOption = InferenceOption(confidenceThreshold: 0.6);
  bool _isInferenceRunning = false;

  // episode
  int _episodeCounter = 0;
  Episode? currentEpisode;
  final List<Episode> episodes = [];
  final _episodeStreamController = StreamController<Episode>.broadcast();
  late final episodeStream = _episodeStreamController.stream;

  // server
  final ServerOption serverOption;
  late final serverConnector = ServerConnector(
    address: serverOption.address,
    token: serverOption.token,
    extraHeaders: {
      'X-FE-Detector': id,
      'X-FE-Domain': serverOption.domainId,
      'X-FE-App-Version': appVersion,
    },
  );

  DetectorInstance({
    required this.id,
    required this.model,
    required this.cameras,
    required this.lift,
    required this.appVersion,
    required this.serverOption,
  });

  // region lifecycle

  DetectorState get currentState => _currentState;

  Future<bool> start() async {
    if (_currentState == DetectorState.starting || _currentState == DetectorState.standby || _currentState == DetectorState.detecting) {
      logger.warning('detector instance ${id} start requested while state is ${_currentState}, skipping');
      _msg('검출기 ${id}는 이미 동작 중입니다 (${_currentState})');
      return true;
    }

    if (_currentState == DetectorState.stopping) {
      logger.warning('detector instance ${id} start requested while stopping, skipping');
      _msg('검출기 ${id} 정지 중에는 시작할 수 없습니다', MessageType.error);
      return false;
    }

    try {
      logger.info('starting detector instance ${id} ...');
      _msg('검출기 ${id} 시작 중 ...', MessageType.important);
      _state(DetectorState.starting);

      // model
      _msg('모델 "${model.name}" 초기화 중 ...');
      final loaded = await model.load();
      if (!loaded) {
        _msg('모델 "${model.name}" 초기화 실패', MessageType.error);
        throw Exception('failed to load model ${model.name}');
      }

      // camera
      _msg('카메라 ${cameras.length}개 초기화 중 ...');
      for (int i = 0; i < cameras.length; i++) {
        final cam = cameras[i];
        if (cam.isCapturing) {
          _msg('카메라 ${cam.runtimeType}는 이미 캡처 중이므로 재시작하지 않음');
          final sub = cam.imageStream.listen((bytes) => _onCameraImage(i, cam, bytes));
          _cameraSubscriptions.add(sub);
          continue;
        }

        _msg('카메라 ${cam.runtimeType} 캡처 시작 중 (${imageSize}x${imageSize}, ${5}fps) ...');
        final started = await cam.startCapturing(width: imageSize, height: imageSize, fps: 5);

        if (!started) {
          _msg('카메라 ${cam.runtimeType} 캡처 시작 실패', MessageType.error);
          throw Exception('failed to start capturing for camera ${cam.runtimeType}');
        }

        final sub = cam.imageStream.listen((bytes) => _onCameraImage(i, cam, bytes));
        _cameraSubscriptions.add(sub);
        _msg('캡처 시작됨');
      }

      // lift
      _msg('리프트 초기화 중 ...');
      _liftSignalSubscription = lift.signalStream.listen(_onLiftSignal);
      if(!lift.isListening){
        final liftStarted = await lift.startListening();
        if (!liftStarted) {
          _msg('리프트 초기화 실패: ${lift.description}', MessageType.error);
          throw Exception('failed to start lift ${lift.description}');
        }
      }


      // server
      _msg('서버 연결 중 ...');

      // all started
      _state(DetectorState.standby);
      return true;
    } catch (e, stt) {
      logger.error('failed to start detector instance ${id}', e, stt);
      await _rollbackStart();
      _state(DetectorState.idle);
      _msg('검출기 시작 중 오류 발생: $e', MessageType.error);
      return false;
    }
  }

  void stop() async {
    _state(DetectorState.stopping);

    // camera
    for (final sub in _cameraSubscriptions) {
      await sub.cancel();
    }
    for (final cam in cameras) {
      await cam.stopCapturing();
    }
    _cameraSubscriptions.clear();

    // lift
    await lift.stopListening();
    await _liftSignalSubscription?.cancel();
    _liftSignalSubscription = null;

    // model
    await model.unLoad();

    _state(DetectorState.idle);
  }

  void _state(DetectorState newState) {
    _currentState = newState;
    logger.info('state changed: ${_currentState}');
    _msg('상태 변경: ${_currentState}', MessageType.important);
  }

  Future<void> _rollbackStart() async {
    for (final sub in _cameraSubscriptions) {
      await sub.cancel();
    }
    _cameraSubscriptions.clear();

    for (final cam in cameras) {
      await cam.stopCapturing();
    }

    await _liftSignalSubscription?.cancel();
    _liftSignalSubscription = null;
    await lift.stopListening();

    await model.unLoad();
  }

  // endregion

  // region message

  int get totalMessagesCount => _totalMessagesCount;

  int get currentMessagesCount => _currentMessagesCount;

  void _msg(String content, [MessageType type = MessageType.info]) {
    messages.add(DetectorMessage(type: type, content: content));
    _totalMessagesCount += 1;
    _currentMessagesCount += 1;

    if (_totalMessagesCount > 250) {
      messages.removeAt(0);
      _totalMessagesCount -= 1;
    }

    _messageStreamController.add(messages.last);
  }

  // endregion

  // region lift

  void _onLiftSignal(LiftSignal signal) async {
    logger.info('received lift signal : ${signal.type}, ${signal.timestamp}');
    _msg('리프트 신호 수신 : ${signal.type}, ${signal.timestamp}');

    switch (signal.type) {
      // elevated
      case LiftSignalType.eggsElevated:
        // check existing episode
        if (currentEpisode != null) {
          logger.warning('previous episode is present but new eggs elevated. ignoring previous episode and creating new one.');
          _msg('불완전 에피소드 종료 발생', MessageType.warning);
          currentEpisode!.error = '불완전 종료됨';
          _episodeStreamController.add(currentEpisode!);
          currentEpisode = null;
          break;
        }

        // create new episode
        _msg('새 에피소드 생성 중 ...', MessageType.important);
        final imageList = _takeImages();
        if (imageList == null) {
          _msg('에피소드 생성 실패 : 이미지 촬영 실패', MessageType.error);
          break;
        }
        final ep = currentEpisode = Episode(
          createTime: DateTime.now().millisecondsSinceEpoch,
          detections: [],
          index: _episodeCounter++,
          eggs: [],
          shots: [],
          imageSize: imageSize,
          objectClasses: model.classes,
          creating: true,
        );
        episodes.add(ep);
        _msg('에피소드 ${ep.index} 생성됨', MessageType.important);
        _updateEpisode(ep, imageList, ep.shots.length + 1 >= lift.shotCount);
        break;

      // rotated
      case LiftSignalType.eggsRotated:
        // check existing episode
        if (currentEpisode == null) {
          logger.warning('eggs rotated signal received but no current episode. waiting for eggs elevated signal.');
          _msg('회전 신호가 상승 신호보다 앞서 감지됨. 상승 신호 대기.', MessageType.warning);
          break;
        }

        // add shot to episode
        _msg('에피소드 ${currentEpisode!.index}에 샷 추가 중 ...', MessageType.important);
        final imageList = _takeImages();
        if (imageList == null) {
          _msg('샷 추가 실패 : 이미지 촬영 실패', MessageType.error);
          break;
        }
        _msg('샷 ${currentEpisode!.shots.length + 1} 추가됨', MessageType.important);
        _updateEpisode(currentEpisode!, imageList, currentEpisode!.shots.length + 1 >= lift.shotCount);
        break;
    }
  }

  // endregion

  // region camera

  void _onCameraImage(int cameraIndex, AbstractCamera camera, Uint8List bytes) {
    logger.info('received image from camera ${cameraIndex} (${camera.runtimeType}), size: ${bytes.lengthInBytes} bytes');
    // _msg('카메라 ${cameraIndex} (${camera.runtimeType})로부터 이미지 수신, 크기: ${bytes.lengthInBytes} bytes');
  }

  // endregion

  // region capture

  CameraImageList? _takeImages() {
    final now = DateTime.now();
    _msg('촬영 중 ...');
    final images = <CameraImage>[];
    for (int i = 0; i < cameras.length; i++) {
      final cam = cameras[i];
      final image = cam.lastImage;

      if (image == null) {
        _msg('카메라 ${i} 이미지 확인 실패, 촬영 중단', MessageType.error);
        return null;
      }

      images.add(
        CameraImage(
          cameraIndex: i,
          bytes: image,
          bytesLength: image.lengthInBytes,
        ),
      );
    }

    _msg('이미지 ${cameras.length}개 촬영 완료');
    return CameraImageList(
      timestamp: now.millisecondsSinceEpoch,
      images: images,
    );
  }

  // endregion

  // region episode

  void _updateEpisode(Episode episode, CameraImageList imageList, bool isFinal) {
    final shot = Shot(
      timestamp: imageList.timestamp,
      images: imageList.images.map((img) => ShotImage(cameraIndex: img.cameraIndex, bytes: img.bytes)).toList(),
      index: episode.shots.length + 0,
    );
    episode.shots.add(shot);
    episode.creating = !isFinal;
    _episodeStreamController.add(episode);
    if (!isFinal) {
      return;
    }
    currentEpisode = null;
    _queueEpisode();
  }


  void _queueEpisode() async {
    if (_isInferenceRunning) {
      return;
    }

    final pendingEpisodes = episodes.where((ep) => !ep.inferred && !ep.creating).toList();
    if (pendingEpisodes.isEmpty) {
      return;
    }

    _isInferenceRunning = true;

    // run
    for (final episode in pendingEpisodes) {
      // inference
      _msg('에피소드 ${episode.index} 추론 시작', MessageType.important);
      final status = episode.inferenceStatus = EpisodeInferenceStatus(startTime: DateTime.now().millisecondsSinceEpoch);
      _episodeStreamController.add(episode);

      final shotDataList = <(List<Egg>,)>[];
      int? eggCount;
      bool eggCountMismatch = false;

      // for shots
      for (final shot in episode.shots) {
        _msg('샷 ${shot.index} 추론 시작');

        final List<Egg> eggs = [];
        final detections = <EpisodeDetection>[];

        // for images
        for (final image in shot.images) {
          // mark
          status.currentCameraIndex = image.cameraIndex;
          status.currentShotIndex = shot.index;
          _episodeStreamController.add(episode);
          _msg('샷 ${shot.index}의 ${image.cameraIndex}번 카메라 이미지 추론 시작');

          // inf
          final imageDetections = await model.detect(Uint8List.fromList(image.bytes), inferenceOption);
          _msg('${imageDetections.length}개 객체 추론됨');

          detections.addAll(
            imageDetections.map((d) => EpisodeDetection(shotIndex: shot.index, cameraIndex: image.cameraIndex, detection: d)),
          );
        }

        // filter eggs and cracks
        final eggDetections = detections.where((d) => eggClasses.contains(d.detection.classIndex)).toList()
          ..sort((d1, d2) => d1.detection.absoluteRect.centerX().compareTo(d2.detection.absoluteRect.centerX()));
        final crackDetections = detections.where((d) => crackClasses.contains(d.detection.classIndex)).toList();

        // create eggs
        for (int i = 0; i < eggDetections.length; i++) {
          final eggDetection = eggDetections[i];
          final egg = Egg(
            index: i,
            cracks: [],
          );
          eggs.add(egg);
        }

        if (eggCount == null) {
          eggCount = eggs.length;
        } else if (eggCount != eggs.length) {
          eggCountMismatch = true;
          _msg('샷 ${shot.index}에서 검출된 계란 객체 수가 이전 샷과 일치하지 않음 (이전: ${eggCount}, 현재: ${eggs.length})', MessageType.warning);
        }

        for (int i = 0; i < crackDetections.length; i++) {
          final crackDetection = crackDetections[i];

          double? closestDistance;
          Egg? closestEgg;

          for (int j = 0; j < eggDetections.length; j++) {
            final eggDetection = eggDetections[j];
            final distance = eggDetection.detection.absoluteRect.centerDistanceTo(crackDetection.detection.absoluteRect);

            if (closestDistance == null || distance < closestDistance) {
              closestDistance = distance;
              closestEgg = eggs[j];
            }
          }

          if (closestEgg != null) {
            closestEgg.cracks.add(
              CrackData(
                shotIndex: shot.index,
                box: crackDetection.detection.absoluteRect,
                confidence: crackDetection.detection.confidence,
              ),
            );
          }
        }

        episode.detections.addAll(detections);
        shotDataList.add((eggs,));
      }

      _msg('에피소드 ${episode.index} 추론 완료. 데이터 생성 중 ...');

      // check all
      if (eggCountMismatch) {
        episode.error = '샷 간 달걀 객체 수 불일치';
        _msg('데이터 생성 실패 : 샷 간 달걀 객체 수 불일치', MessageType.warning);
      } else if (eggCount == null) {
        episode.error = '달걀 객체 검출 실패';
        _msg('데이터 생성 실패 : 달걀 객체가 하나도 검출되지 않음', MessageType.warning);
      }
      // valid
      else {
        for (int e = 0; e < eggCount; e++) {
          final egg = Egg(index: e, cracks: []);

          for (final data in shotDataList) {
            final shotEggs = data.$1;
            egg.cracks.addAll(shotEggs[e].cracks);
          }
          episode.eggs.add(egg);
        }

        _msg('데이터 생성 완료 : ${episode.eggs.length}개의 달걀', MessageType.important);
      }

      // episode
      episode.inferenceStatus = null;
      episode.inferred = true;
      _msg('${episode.index}차 에피소드 데이터 생성 완료.', MessageType.important);
      _episodeStreamController.add(episode);

      // server
      final reported = await _reportEpisode(episode, {
        // TODO
      });
      if (reported) {
        _msg('${episode.index}차 에피소드 서버 전송 완료', MessageType.important);
      } else {
        _msg('${episode.index}차 에피소드 서버 전송 실패', MessageType.error);
      }
    }

    // start new?
    _isInferenceRunning = false;
    if (episodes.where((ep) => !ep.inferred && !ep.creating).isEmpty) {
      return;
    }
    _queueEpisode();
  }

  // endregion

  // region server

  Future<bool> _reportEpisode(Episode episode, Map<int, Uint8List> images) async {
    final status = await serverConnector.postForm('/episode', (request) {
      request.fields['data'] = jsonEncode(episode.toJson());
      for (final entry in images.entries) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image_${entry.key}',
            entry.value,
            filename: 'image_${entry.key}.jpg',
          ),
        );
      }
    });
    return status == 200;
  }

  // endregion
}
