import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerlyss/presentation/common/mini_player.dart';
import 'package:kerlyss/presentation/state/audio_provider.dart';
import 'package:kerlyss/presentation/state/audio_state.dart';
import 'package:kerlyss/presentation/state/library_provider.dart';

class _MockAudioNotifier extends StateNotifier<AudioState> implements AudioNotifier {
  _MockAudioNotifier()
      : super(const AudioState(
          status: PlaybackStatus.idle,
          position: Duration.zero,
          bufferedPosition: Duration.zero,
          currentSong: SongMetadata(id: '', title: '', artist: '', duration: Duration.zero),
        ));

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
}
