abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network request failed.']) : super(message);
}

class ParsingFailure extends Failure {
  const ParsingFailure([String message = 'Failed to parse response.']) : super(message);
}

class StorageFailure extends Failure {
  const StorageFailure([String message = 'Local storage operation failed.']) : super(message);
}

class SearchFailure extends Failure {
  const SearchFailure([String message = 'Search operation failed.']) : super(message);
}

class AudioPlaybackFailure extends Failure {
  const AudioPlaybackFailure([String message = 'Audio playback failed.']) : super(message);
}
