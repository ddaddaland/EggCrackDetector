class ServerOption {
  final String displayName;
  final String address;
  final String token;
  final String domainId;

  ServerOption({
    required this.displayName,
    required this.address,
    required this.token,
    required this.domainId,
  });

  String url(String path) {
    return '$address/fe$path';
  }
}
