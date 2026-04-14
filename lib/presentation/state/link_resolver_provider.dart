import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_state.dart';
import 'dart:async';
import '../../data/repositories/repository_providers.dart';
import '../../domain/repositories/song_repository.dart';

enum LinkResolverStatus { idle, resolving, success, error }

class LinkResolverState {
  final LinkResolverStatus status;
  final SongMetadata? resolvedSong;
  final String? errorMessage;

  const LinkResolverState({
    this.status = LinkResolverStatus.idle,
    this.resolvedSong,
    this.errorMessage,
  });

  LinkResolverState copyWith({
    LinkResolverStatus? status,
    SongMetadata? resolvedSong,
    String? errorMessage,
  }) {
    return LinkResolverState(
      status: status ?? this.status,
      resolvedSong: resolvedSong ?? this.resolvedSong,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final linkResolverProvider = StateNotifierProvider<LinkResolverNotifier, LinkResolverState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  return LinkResolverNotifier(repository);
});

class LinkResolverNotifier extends StateNotifier<LinkResolverState> {
  final SongRepository _repository;

  LinkResolverNotifier(this._repository) : super(const LinkResolverState());

  Future<void> resolveLink(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;

    state = state.copyWith(status: LinkResolverStatus.resolving);

    try {
      final entity = await _repository.getSongFromSpotifyUrl(url);

      final resolvedSong = SongMetadata(
        id: entity.id,
        title: entity.title,
        artist: entity.artist,
        album: entity.album,
        duration: entity.duration,
        artworkUrl: entity.albumArtUrl,
        source: entity.sourceType,
      );

      state = state.copyWith(
        status: LinkResolverStatus.success,
        resolvedSong: resolvedSong,
      );
    } catch (e) {
      state = state.copyWith(
        status: LinkResolverStatus.error,
        errorMessage: 'Failed to resolve link: ${e.toString()}',
      );
    }
  }

  void cancel() {
    state = const LinkResolverState(status: LinkResolverStatus.idle);
  }

  void reset() {
    state = const LinkResolverState(status: LinkResolverStatus.idle);
  }
}
