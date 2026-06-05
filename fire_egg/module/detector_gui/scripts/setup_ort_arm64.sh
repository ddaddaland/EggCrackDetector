#!/usr/bin/env bash
# =============================================================================
# setup_ort_arm64.sh
#
# Jetson(aarch64) 환경에서 flutter build linux 전에 실행해야 하는 셋업 스크립트.
# onnxruntime Flutter 패키지의 Linux 바이너리는 x86-64 전용이므로,
# 이 스크립트가 arm64 Linux 바이너리를 다운로드하고 플러그인 디렉터리에 교체합니다.
#
# 사용법:
#   cd module/detector_gui
#   bash scripts/setup_ort_arm64.sh
#
# 선택적 환경 변수:
#   ORT_VERSION    - 다운로드할 버전 (기본: 1.15.1)
#   ORT_LIB_PATH   - 직접 arm64 라이브러리 경로 지정 (다운로드 생략)
# =============================================================================

set -e

ORT_VERSION="${ORT_VERSION:-1.15.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$SCRIPT_DIR/cache"
PLUGIN_DIR="$SCRIPT_DIR/../linux/flutter/ephemeral/.plugin_symlinks/onnxruntime/linux"
DEST_LIB="$PLUGIN_DIR/libonnxruntime.so.1.15.1"
CACHE_LIB="$CACHE_DIR/libonnxruntime_arm64.so.$ORT_VERSION"

DOWNLOAD_URL="https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/onnxruntime-linux-aarch64-${ORT_VERSION}.tgz"
TMP_TGZ="/tmp/onnxruntime-linux-aarch64-${ORT_VERSION}.tgz"
TMP_DIR="/tmp/ort_extract_$$"

# ---------------------------------------------------------------------------
# 아키텍처 확인
# ---------------------------------------------------------------------------
ARCH=$(uname -m)
echo "시스템 아키텍처: $ARCH"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
  echo "[경고] 현재 시스템이 aarch64/arm64 이 아닙니다 ($ARCH)."
  echo "  x86-64 개발 PC에서는 이 스크립트가 필요하지 않습니다."
  echo "  Jetson에서 flutter build linux 전에 실행하세요."
  exit 0
fi

# ---------------------------------------------------------------------------
# 직접 경로가 지정된 경우
# ---------------------------------------------------------------------------
if [[ -n "$ORT_LIB_PATH" ]]; then
  echo "사용자 지정 라이브러리 사용: $ORT_LIB_PATH"
  if [[ ! -f "$ORT_LIB_PATH" ]]; then
    echo "[오류] 파일이 존재하지 않습니다: $ORT_LIB_PATH"
    exit 1
  fi
  FILE_INFO=$(file "$ORT_LIB_PATH" 2>/dev/null || echo "file 명령 없음")
  echo "  파일 정보: $FILE_INFO"
  if echo "$FILE_INFO" | grep -q "x86-64"; then
    echo "[오류] 지정한 파일이 x86-64 입니다. aarch64 라이브러리를 지정하세요."
    exit 1
  fi
  cp "$ORT_LIB_PATH" "$CACHE_LIB"
  echo "캐시에 저장: $CACHE_LIB"
fi

# ---------------------------------------------------------------------------
# 캐시 확인 또는 다운로드
# ---------------------------------------------------------------------------
mkdir -p "$CACHE_DIR"

if [[ -f "$CACHE_LIB" ]]; then
  FILE_INFO=$(file "$CACHE_LIB" 2>/dev/null || echo "")
  echo "캐시된 arm64 라이브러리 발견: $CACHE_LIB"
  echo "  파일 정보: $FILE_INFO"
  if echo "$FILE_INFO" | grep -q "x86-64"; then
    echo "[경고] 캐시된 파일이 x86-64 입니다. 다시 다운로드합니다."
    rm -f "$CACHE_LIB"
  fi
fi

if [[ ! -f "$CACHE_LIB" ]]; then
  echo "GitHub에서 다운로드 중..."
  echo "  URL: $DOWNLOAD_URL"

  # /tmp에 이미 다운로드된 파일이 있으면 재사용
  if [[ ! -f "$TMP_TGZ" ]]; then
    wget --show-progress -O "$TMP_TGZ" "$DOWNLOAD_URL" || {
      echo "[오류] 다운로드 실패"
      echo "수동으로 아래 파일을 준비해서 다음 경로에 놓아주세요:"
      echo "  $CACHE_LIB"
      exit 1
    }
  else
    echo "  임시 파일 재사용: $TMP_TGZ"
  fi

  echo "압축 해제 중..."
  mkdir -p "$TMP_DIR"
  tar -xzf "$TMP_TGZ" -C "$TMP_DIR" --wildcards '*/lib/libonnxruntime.so*' 2>/dev/null || \
  tar -xzf "$TMP_TGZ" -C "$TMP_DIR" 2>/dev/null

  # 압축 해제된 파일 검색
  EXTRACTED=$(find "$TMP_DIR" -name 'libonnxruntime.so.*' | head -n 1)
  if [[ -z "$EXTRACTED" ]]; then
    EXTRACTED=$(find "$TMP_DIR" -name 'libonnxruntime.so' | head -n 1)
  fi

  if [[ -z "$EXTRACTED" ]]; then
    echo "[오류] 아카이브에서 libonnxruntime.so 를 찾을 수 없습니다."
    ls -la "$TMP_DIR" || true
    ls -la "$TMP_DIR"/*/ 2>/dev/null || true
    exit 1
  fi

  echo "  추출된 파일: $EXTRACTED"
  echo "  파일 정보: $(file "$EXTRACTED")"

  # 아키텍처 재확인
  if file "$EXTRACTED" | grep -q "x86-64"; then
    echo "[오류] 압축 파일 내 라이브러리가 x86-64 입니다."
    exit 1
  fi

  cp "$EXTRACTED" "$CACHE_LIB"
  echo "캐시에 저장: $CACHE_LIB"
  rm -rf "$TMP_DIR"
fi

# ---------------------------------------------------------------------------
# 플러그인 디렉터리에 교체
# ---------------------------------------------------------------------------
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "[경고] 플러그인 디렉터리가 없습니다: $PLUGIN_DIR"
  echo "  flutter pub get 을 먼저 실행하세요."
  echo "  캐시만 저장됩니다. flutter pub get 후 이 스크립트를 다시 실행하세요."
  exit 0
fi

# 기존 x86-64 라이브러리 백업
if [[ -f "$DEST_LIB" ]]; then
  DEST_BACKUP="${DEST_LIB}.x86_64.bak"
  if [[ ! -f "$DEST_BACKUP" ]]; then
    cp "$DEST_LIB" "$DEST_BACKUP"
    echo "기존 x86-64 라이브러리 백업: $DEST_BACKUP"
  fi
fi

cp "$CACHE_LIB" "$DEST_LIB"
echo ""
echo "========================================================"
echo "완료! arm64 ONNX Runtime 라이브러리 교체 성공"
echo "  대상: $DEST_LIB"
echo "  파일 정보: $(file "$DEST_LIB")"
echo ""
echo "이제 다음 명령으로 빌드하세요:"
echo "  flutter build linux"
echo "또는 개발 실행:"
echo "  flutter run -d linux"
echo "========================================================"

