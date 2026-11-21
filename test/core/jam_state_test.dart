import 'package:flutter_test/flutter_test.dart';
import 'package:kerlyss/core/services/jam_state.dart';

JamState state({
  int rev = 1,
  String songId = 'lab-1',
  bool playing = true,
  int positionMs = 10000,
  required DateTime writtenAt,
  String writer = 'android-1111',
}) =>
    JamState(
      rev: rev,
      songId: songId,
      title: 'Test $songId',
      playing: playing,
      positionMs: positionMs,
      writtenAt: writtenAt,
      writer: writer,
    );

void main() {
  final t0 = DateTime.utc(2026, 11, 1, 12, 0, 0);

  group('JamState', () {
    test('survives an encode / parse round trip', () {
      final parsed = JamState.tryParse(state(rev: 4, positionMs: 12345, writtenAt: t0).encode());

      expect(parsed, isNotNull);
      expect(parsed!.rev, 4);
      expect(parsed.songId, 'lab-1');
      expect(parsed.playing, isTrue);
      expect(parsed.positionMs, 12345);
      expect(parsed.writtenAt, t0);
      expect(parsed.writer, 'android-1111');
    });

    test('anything else gives null and never throws', () {
      expect(JamState.tryParse(''), isNull);
      expect(JamState.tryParse('not json'), isNull);
      expect(JamState.tryParse('[]'), isNull);
      expect(JamState.tryParse('{}'), isNull);
      expect(JamState.tryParse('{"rev":"1"}'), isNull);
    });

    test('live position moves with time while playing', () {
      final s = state(positionMs: 10000, writtenAt: t0);
      expect(s.livePositionMs(t0.add(const Duration(seconds: 5))), 15000);
    });

    test('live position stays while paused', () {
      final s = state(playing: false, positionMs: 10000, writtenAt: t0);
      expect(s.livePositionMs(t0.add(const Duration(seconds: 5))), 10000);
    });

    test('a clock that is slightly behind never moves the position backwards', () {
      final s = state(positionMs: 10000, writtenAt: t0);
      expect(s.livePositionMs(t0.subtract(const Duration(seconds: 1))), 10000);
    });
  });

  group('JamState.decide', () {
    JamDecision decide(
      JamState remote, {
      String myWriter = 'windows-2222',
      DateTime? lastLocalChangeAt,
      String songId = 'lab-1',
      bool playing = true,
      int positionMs = 10000,
      DateTime? now,
    }) =>
        JamState.decide(
          remote: remote,
          myWriter: myWriter,
          lastLocalChangeAt: lastLocalChangeAt,
          localSongId: songId,
          localPlaying: playing,
          localPositionMs: positionMs,
          now: now ?? t0,
        );

    test('my own file is never applied', () {
      final remote = state(writer: 'windows-2222', songId: 'lab-9', writtenAt: t0);
      expect(decide(remote), JamDecision.ignore);
    });

    test('another song is applied', () {
      expect(decide(state(songId: 'lab-2', writtenAt: t0)), JamDecision.apply);
    });

    test('a play / pause change is applied', () {
      expect(decide(state(playing: false, writtenAt: t0)), JamDecision.apply);
    });

    test('a big jump (seek) is applied', () {
      expect(decide(state(positionMs: 40000, writtenAt: t0)), JamDecision.apply);
    });

    test('a small difference is left alone', () {
      expect(decide(state(positionMs: 11500, writtenAt: t0)), JamDecision.ignore);
    });

    test('a heartbeat that matches my own live position is ignored', () {
      // Remote said 10 s at t0 and plays on. Five seconds later I am at 15 s too.
      final remote = state(positionMs: 10000, writtenAt: t0);
      expect(decide(remote, positionMs: 15000, now: t0.add(const Duration(seconds: 5))), JamDecision.ignore);
    });

    test('a state older than my last action is ignored (my action wins)', () {
      final remote = state(songId: 'lab-2', writtenAt: t0);
      expect(decide(remote, lastLocalChangeAt: t0.add(const Duration(seconds: 1))), JamDecision.ignore);
    });

    test('a state newer than my last action is applied', () {
      final remote = state(songId: 'lab-2', writtenAt: t0.add(const Duration(seconds: 2)));
      expect(decide(remote, lastLocalChangeAt: t0), JamDecision.apply);
    });

    test('two people acting at once end on the later one on both devices', () {
      final early = state(writer: 'android-1111', playing: false, writtenAt: t0);
      final late = state(writer: 'windows-2222', playing: true, writtenAt: t0.add(const Duration(seconds: 1)));

      // Android acted at t0, Windows at t0 + 1 s. Each reads the other's file.
      final androidSees = JamState.decide(
        remote: late,
        myWriter: 'android-1111',
        lastLocalChangeAt: early.writtenAt,
        localSongId: 'lab-1',
        localPlaying: false,
        localPositionMs: 10000,
        now: t0.add(const Duration(seconds: 3)),
      );
      final windowsSees = JamState.decide(
        remote: early,
        myWriter: 'windows-2222',
        lastLocalChangeAt: late.writtenAt,
        localSongId: 'lab-1',
        localPlaying: true,
        localPositionMs: 10000,
        now: t0.add(const Duration(seconds: 3)),
      );

      expect(androidSees, JamDecision.apply);
      expect(windowsSees, JamDecision.ignore);
    });
  });
}
