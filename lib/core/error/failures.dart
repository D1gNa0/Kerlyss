abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network request failed.']);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Failed to parse response.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local storage operation failed.']);
}

class SearchFailure extends Failure {
  const SearchFailure([super.message = 'Search operation failed.']);
}

class AudioPlaybackFailure extends Failure {
  const AudioPlaybackFailure([super.message = 'Audio playback failed.']);
}
