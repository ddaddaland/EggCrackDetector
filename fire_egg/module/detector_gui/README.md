# fire_egg_detector_gui

## ONNX Runtime / Jetson Orin Nano 대응 메모

이 프로젝트의 현재 `load()` 실패 원인은 다음과 같습니다.

- 앱이 `libonnxruntime.so.1.15.1`를 찾았지만, 실제 파일은 **x86-64** 빌드입니다.
- 현재 실행 환경은 **aarch64(Jetson 계열)** 이므로 해당 라이브러리를 로드할 수 없습니다.
- 즉, 파일 존재 여부 문제가 아니라 **아키텍처 불일치 문제**입니다.

## 권장 아키텍처

가장 안정적인 구성은 아래와 같습니다.

1. **Flutter 공통 인터페이스** 유지
2. **네이티브 브리지(FFI)** 로 ONNX Runtime C API 호출
3. Windows: **CUDA EP** 우선
4. Jetson Linux: **TensorRT EP** 우선, 실패 시 **CUDA EP**, 마지막에 **CPU EP**

이 방식이 가장 안정적인 이유는 다음과 같습니다.

- Flutter에서 동적 라이브러리 경로를 직접 제어할 수 있습니다.
- Jetson 전용 arm64 ORT 바이너리를 명시적으로 넣을 수 있습니다.
- TensorRT/ CUDA 옵션을 세밀하게 제어할 수 있습니다.

## 현재 코드에서 확인할 사항

`module/detector/lib/model/onnx.dart` 는 다음 순서로 라이브러리를 찾습니다.

1. `FIRE_EGG_ORT_LIB` 환경 변수
2. 실행 파일 기준 `lib/`
3. 개발 빌드 bundle 경로
4. `/usr/lib/aarch64-linux-gnu/`, `/usr/local/lib/`, `/opt/onnxruntime/lib/`

즉, Jetson에서는 **arm64용 `libonnxruntime.so.1.15.1`** 를 위 경로 중 하나에 두거나,
`FIRE_EGG_ORT_LIB` 로 절대 경로를 지정해야 합니다.

## 즉시 확인할 명령

```bash
uname -m
file /경로/libonnxruntime.so.1.15.1
ldd /경로/libonnxruntime.so.1.15.1 | cat
```

## 실행 예시

```bash
export FIRE_EGG_ORT_LIB="/usr/lib/aarch64-linux-gnu/libonnxruntime.so.1.15.1"
export LD_LIBRARY_PATH="$(dirname "$FIRE_EGG_ORT_LIB"):$LD_LIBRARY_PATH"
flutter run -d linux
```

## 권장 배포 팁

- Jetson용은 **aarch64 ORT** 를 별도로 준비하세요.
- Windows용은 **onnxruntime.dll** 을 별도로 준비하세요.
- 두 플랫폼 모두 동일한 Dart 인터페이스를 사용하되, 네이티브 라이브러리만 분리하는 구조가 가장 안전합니다.

## 참고

현재 설치된 `onnxruntime` 패키지의 Linux 바이너리가 잘못된 아키텍처로 들어오는 경우가 있으므로,
장기적으로는 **커스텀 FFI 브리지 + 직접 빌드한 ONNX Runtime** 방식이 가장 안정적입니다.
