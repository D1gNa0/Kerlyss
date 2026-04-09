import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_state.dart';
import 'dart:async';

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
  return LinkResolverNotifier();
});

class LinkResolverNotifier extends StateNotifier<LinkResolverState> {
  LinkResolverNotifier() : super(const LinkResolverState());

  Future<void> resolveLink(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;

    state = state.copyWith(status: LinkResolverStatus.resolving);

    try {
      // Mocking the "Hybrid Bridge" resolution logic for Phase 3
      // In a real scenario, this would call Spotify/YouTube repositories
      await Future.delayed(const Duration(seconds: 3));

      final mockResolvedSong = SongMetadata(
        id: 'external_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Resolved Aether Track',
        artist: 'Hybrid Artist',
        duration: const Duration(minutes: 4, seconds: 20),
        artworkUrl: 'https://picsum.photos/seed/resolved/400/400',
      );

      state = state.copyWith(
        status: LinkResolverStatus.success,
        resolvedSong: mockResolvedSong,
      );
    } catch (e) {
      state = state.copyWith(
        status: LinkResolverStatus.error,
        errorMessage: 'Failed to resolve link',
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
