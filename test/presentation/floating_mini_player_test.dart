import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/presentation/common/mini_player.dart';
import 'package:kerlyss/presentation/state/audio_provider.dart';
import 'package:kerlyss/presentation/state/audio_state.dart';
import 'package:kerlyss/presentation/state/library_provider.dart';

class _MockAudioNotifier extends StateNotifier<AudioState> implements AudioNotifier {
  bool toggleRepeatCalled = false;

  _MockAudioNotifier({AudioState? initial})
      : super(initial ??
            const AudioState(
              status: PlaybackStatus.idle,
              position: Duration.zero,
              bufferedPosition: Duration.zero,
              currentSong: SongMetadata(id: '', title: '', artist: '', duration: Duration.zero),
            ));

  @override
  void toggleRepeatMode() {
    toggleRepeatCalled = true;
    final next = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockLibraryNotifier extends StateNotifier<LibraryState> implements LibraryNotifier {
  _MockLibraryNotifier() : super(const LibraryState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MiniPlayer renders floating pill container with rounded corners', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioProvider.overrideWith((ref) => _MockAudioNotifier()),
          libraryProvider.overrideWith((ref) => _MockLibraryNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MiniPlayer(),
          ),
        ),
      ),
    );

    expect(find.byType(MiniPlayer), findsOneWidget);
  });

  testWidgets('MiniPlayer renders Repeat button and toggles repeat mode when active song is present', (tester) async {
    final notifier = _MockAudioNotifier(
      initial: const AudioState(
        status: PlaybackStatus.playing,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
        repeatMode: PlaybackRepeatMode.off,
        currentSong: SongMetadata(
          id: 'test_song_1',
          title: 'Echoes of Silence',
          artist: 'Kerlyss',
          duration: Duration(minutes: 3),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioProvider.overrideWith((ref) => notifier),
          libraryProvider.overrideWith((ref) => _MockLibraryNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MiniPlayer(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

    // Tap the repeat button
    await tester.tap(find.byIcon(Icons.repeat_rounded));
    await tester.pumpAndSettle();

    expect(notifier.toggleRepeatCalled, isTrue);
    expect(notifier.state.repeatMode, equals(PlaybackRepeatMode.all));
  });
}
