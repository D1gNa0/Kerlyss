class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server Exception']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Exception']);
}
