class DetectorImageSize {
  const DetectorImageSize._();

  static const int size640 = 640;
  static const int size1280 = 1280;

  static const List<int> supported = [size640, size1280];
  static const int defaultSize = size640;

  static bool isSupported(int value) => supported.contains(value);
}
