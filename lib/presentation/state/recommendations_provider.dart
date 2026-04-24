import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../core/services/stream_resolution_cache.dart';
import '../../data/datasources/remote/deezer_public_service.dart';
import '../../data/repositories/repository_providers.dart';
import 'library_provider.dart';
import 'download_state_provider.dart';

class RecommendationState {
  final List<SongEntity> similarSongs;
  final List<SongEntity> trendingSongs;
  final Map<String, String> similarReasons;
  final String? baseIdeaArtist;
  final bool isLoading;
  final DateTime? lastFetchedAt;

  RecommendationState({
    required this.similarSongs,
    required this.trendingSongs,
    this.similarReasons = const {},
    this.baseIdeaArtist,
    this.isLoading = false,
    this.lastFetchedAt,
  });

  RecommendationState copyWith({
    List<SongEntity>? similarSongs,
    List<SongEntity>? trendingSongs,
    Map<String, String>? similarReasons,
    String? baseIdeaArtist,
    bool clearBaseIdeaArtist = false,
    bool? isLoading,
    DateTime? lastFetchedAt,
  }) {
    return RecommendationState(
      similarSongs: similarSongs ?? this.similarSongs,
      trendingSongs: trendingSongs ?? this.trendingSongs,
      similarReasons: similarReasons ?? this.similarReasons,
      baseIdeaArtist: clearBaseIdeaArtist ? null : (baseIdeaArtist ?? this.baseIdeaArtist),
      isLoading: isLoading ?? this.isLoading,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}

final recommendationsProvider = StateNotifierProvider<RecommendationsNotifier, RecommendationState>((ref) {
  final deezerService = ref.watch(deezerPublicServiceProvider);
  return RecommendationsNotifier(ref, deezerService);
});

class RecommendationsNotifier extends StateNotifier<RecommendationState> {
  static const int _targetCount = 12;
  static const Duration _cacheTtl = Duration(minutes: 10);

  static final RegExp _nonTrackTitlePattern = RegExp(
    r'(\bmix\b|\bmegamix\b|\bplaylist\b|\bcompilation\b|\bfull\s*album\b|\bfull\s*ep\b|\bdj\s*set\b|\blive\s*set\b|\bnonstop\b)',
    caseSensitive: false,
  );

  final Ref _ref;
  final DeezerPublicService _deezerService;
  final Random _random = Random();
  DateTime? _lastInvalidatedAt;
  DateTime? _nextRetryAllowedAt;

  RecommendationsNotifier(this._ref, this._deezerService)
      : super(RecommendationState(similarSongs: [], trendingSongs: [], isLoading: false)) {
    _listenToSignalChanges();
  }

  Future<void> fetchRecommendations({bool force = false}) async {
    if (state.isLoading) return;
    if (!force && _nextRetryAllowedAt != null && DateTime.now().isBefore(_nextRetryAllowedAt!)) {
      return;
    }
    if (!force && !_shouldRefresh()) return;

    state = state.copyWith(isLoading: true);

    try {
      final libraryState = _ref.read(libraryProvider);
      final library = libraryState.allSongs;
      final favoriteIds = libraryState.favoriteSongs.map((s) => s.id).toSet();
      final downloadedIds = _ref.read(downloadStateProvider).alreadyDownloadedIds;

      final localIds = library.where((s) => s.localPath != null).map((s) => s.id).toSet();
      final excludedIds = <String>{...favoriteIds, ...downloadedIds, ...localIds};

      final candidateIds = <String>{};
      final reasonById = <String, String>{};
      final scoreById = <String, int>{};

      List<SongEntity> similar = <SongEntity>[];
      List<SongEntity> trending = <SongEntity>[];
      String? ideaArtist;

      final trendingResultsFuture = _deezerService.searchTracks('top hits');
      final secondPassResultsFuture = _deezerService.searchTracks('new releases');
      Future<List<SongEntity>>? fallbackResultsFuture;

      // Trending pool: use Deezer chart queries for pristine metadata
      final trendingResults = await trendingResultsFuture;
      trending = trendingResults
          .where((song) => !excludedIds.contains(song.id) && _isSingleTrack(song))
          .toList();

      // Personalized tiers (A: related, B: artist queries, C: fallback singles)
      if (library.isNotEmpty) {
        fallbackResultsFuture = _deezerService.searchTracks('popular music');
        final seeds = _pickSeeds(libraryState.favoriteSongs, library);
        if (seeds.isNotEmpty) {
          ideaArtist = seeds.first.artist;

          for (final seed in seeds) {
            final seedResults = await Future.wait<List<SongEntity>>([
              _deezerService.searchTracks(seed.artist),
              _deezerService.searchTracks('${seed.artist} ${seed.title}'),
            ]);

            // Tier A: Deezer artist search using clean library artist name
            final artistResults = seedResults[0];
            _mergeCandidates(
              pool: similar,
              incoming: artistResults,
              excludedIds: excludedIds,
              candidateIds: candidateIds,
              scoreById: scoreById,
              reasonById: reasonById,
              seedArtist: seed.artist,
              tierScore: 2,
              reason: 'ARTIST MATCH',
            );

            if (similar.length >= _targetCount) {
              break;
            }

            // Tier B: genre-adjacent Deezer search using title keywords
            final relatedResults = seedResults[1];
            _mergeCandidates(
              pool: similar,
              incoming: relatedResults,
              excludedIds: excludedIds,
              candidateIds: candidateIds,
              scoreById: scoreById,
              reasonById: reasonById,
              seedArtist: seed.artist,
              tierScore: 1,
              reason: 'RELATED',
            );

            if (similar.length >= _targetCount) {
              break;
            }
          }

          // Tier C: global fallback using popular Deezer queries
          if (similar.length < _targetCount) {
            final fallbackResults = await fallbackResultsFuture!;
            _mergeCandidates(
              pool: similar,
              incoming: fallbackResults,
              excludedIds: excludedIds,
              candidateIds: candidateIds,
              scoreById: scoreById,
              reasonById: reasonById,
              seedArtist: seeds.first.artist,
              tierScore: 0,
              reason: 'TRENDING FALLBACK',
            );
          }
        }
      } else {
        ideaArtist = null;

        // Library empty: populate from Deezer trending
        final fallbackResults = await _deezerService.searchTracks('top hits');
        _mergeCandidates(
          pool: similar,
          incoming: fallbackResults,
          excludedIds: excludedIds,
          candidateIds: candidateIds,
          scoreById: scoreById,
          reasonById: reasonById,
          seedArtist: '',
          tierScore: 0,
          reason: 'TRENDING FALLBACK',
        );
      }

      // Second pass: supplement with more Deezer results if under target
      if (similar.length < _targetCount) {
        final secondPassResults = await secondPassResultsFuture;
        _mergeCandidates(
          pool: similar,
          incoming: secondPassResults,
          excludedIds: excludedIds,
          candidateIds: candidateIds,
          scoreById: scoreById,
          reasonById: reasonById,
          seedArtist: ideaArtist ?? '',
          tierScore: 0,
          reason: 'TRENDING FALLBACK',
        );
      }

      similar = _rankAndTrim(similar, scoreById, _targetCount);

      // Safety net: if personalized pool is empty but trending exists, fill from trending.
      if (similar.isEmpty && trending.isNotEmpty) {
        final backfill = trending.take(min(4, trending.length)).toList();
        similar = backfill;
        for (final song in backfill) {
          reasonById[song.id] = 'TRENDING FALLBACK';
        }
      }

      final trimmedReasons = <String, String>{
        for (final song in similar)
          song.id: reasonById[song.id] ?? 'ARTIST MATCH',
      };

      final now = DateTime.now();
      _nextRetryAllowedAt = null;
      if (mounted) {
        state = state.copyWith(
          similarSongs: similar,
          trendingSongs: trending.take(_targetCount).toList(),
          similarReasons: trimmedReasons,
          baseIdeaArtist: ideaArtist,
          clearBaseIdeaArtist: ideaArtist == null,
          isLoading: false,
          lastFetchedAt: now,
        );

        _prefetchPlaybackCandidates(similar, trending);
      }
    } catch (e) {
      _nextRetryAllowedAt = DateTime.now().add(const Duration(seconds: 30));
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
        );
      }
    }
  }

  void _prefetchPlaybackCandidates(List<SongEntity> similar, List<SongEntity> trending) {
    final candidates = <SongEntity>[];
    final seenIds = <String>{};

    for (final song in [...similar, ...trending]) {
      if (seenIds.add(song.id)) {
        candidates.add(song);
      }

      if (candidates.length >= 5) {
        break;
      }
    }

    if (candidates.isEmpty) return;

    unawaited(StreamResolutionCache.instance.prefetch(candidates, _ref.read(songRepositoryProvider)));
  }

  void refresh() {
    _lastInvalidatedAt = DateTime.now();
    fetchRecommendations(force: true);
  }

  bool _shouldRefresh() {
    final now = DateTime.now();
    final lastFetchedAt = state.lastFetchedAt;
    if (lastFetchedAt == null) return true;
    if (now.difference(lastFetchedAt) > _cacheTtl) return true;

    if (_lastInvalidatedAt != null && _lastInvalidatedAt!.isAfter(lastFetchedAt)) {
      return true;
    }

    return false;
  }

  void _listenToSignalChanges() {
    _ref.listen<LibraryState>(libraryProvider, (previous, next) {
      if (previous == null) return;

      final previousFavoriteIds = previous.favoriteSongs.map((s) => s.id).toSet();
      final nextFavoriteIds = next.favoriteSongs.map((s) => s.id).toSet();
      final favoriteChanged = previousFavoriteIds.length != nextFavoriteIds.length ||
          !previousFavoriteIds.containsAll(nextFavoriteIds);
      if (favoriteChanged) {
        _lastInvalidatedAt = DateTime.now();
        fetchRecommendations();
      }
    });

    _ref.listen<DownloadState>(downloadStateProvider, (previous, next) {
      if (previous == null) return;

      final downloadedChanged = previous.alreadyDownloadedIds.length != next.alreadyDownloadedIds.length ||
          !previous.alreadyDownloadedIds.containsAll(next.alreadyDownloadedIds);
      if (downloadedChanged) {
        _lastInvalidatedAt = DateTime.now();
        fetchRecommendations();
      }
    });
  }

  List<SongEntity> _pickSeeds(
    List<SongEntity> favorites,
    List<SongEntity> library,
  ) {
    final now = DateTime.now();
    final merged = <SongEntity>{...favorites, ...library}.toList();
    if (merged.isEmpty) return const [];

    merged.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final weighted = <SongEntity>[];
    for (final song in merged.take(25)) {
      final ageDays = max(1, now.difference(song.dateAdded).inDays);
      final isFavorite = favorites.any((f) => f.id == song.id);
      final weight = (isFavorite ? 6 : 3) + max(1, 30 ~/ ageDays);
      for (var i = 0; i < weight; i++) {
        weighted.add(song);
      }
    }

    final picks = <SongEntity>[];
    final seenArtists = <String>{};
    while (picks.length < 3 && weighted.isNotEmpty) {
      final candidate = weighted[_random.nextInt(weighted.length)];
      if (seenArtists.add(candidate.artist.toLowerCase())) {
        picks.add(candidate);
      }
      weighted.removeWhere((s) => s.id == candidate.id);
    }

    if (picks.isEmpty) {
      picks.add(merged.first);
    }

    return picks;
  }

  void _mergeCandidates({
    required List<SongEntity> pool,
    required List<SongEntity> incoming,
    required Set<String> excludedIds,
    required Set<String> candidateIds,
    required Map<String, int> scoreById,
    required Map<String, String> reasonById,
    required String seedArtist,
    required int tierScore,
    required String reason,
  }) {
    for (final song in incoming) {
      if (pool.length >= _targetCount * 2) {
        return;
      }
      if (excludedIds.contains(song.id) || candidateIds.contains(song.id)) {
        continue;
      }
      if (!_isSingleTrack(song)) {
        continue;
      }

      final score = _scoreSong(song, seedArtist, tierScore);
      pool.add(song);
      candidateIds.add(song.id);
      scoreById[song.id] = score;
      reasonById[song.id] = reason;
    }
  }

  int _scoreSong(SongEntity song, String seedArtist, int tierScore) {
    final artist = song.artist.toLowerCase();
    final title = song.title.toLowerCase();
    final seed = seedArtist.toLowerCase();

    var score = 0;
    if (seed.isNotEmpty && artist == seed) {
      score += 3;
    } else if (seed.isNotEmpty && (artist.contains(seed) || title.contains(seed))) {
      score += 2;
    }

    score += tierScore;

    // Small tie-breaker by shorter single-friendly duration range.
    if (song.duration.inSeconds >= 120 && song.duration.inSeconds <= 330) {
      score += 1;
    }

    return score;
  }

  List<SongEntity> _rankAndTrim(
    List<SongEntity> songs,
    Map<String, int> scoreById,
    int maxCount,
  ) {
    final byArtistCount = <String, int>{};
    final sorted = List<SongEntity>.from(songs)
      ..sort((a, b) {
        final scoreCompare = (scoreById[b.id] ?? 0).compareTo(scoreById[a.id] ?? 0);
        if (scoreCompare != 0) return scoreCompare;
        return a.id.compareTo(b.id);
      });

    final result = <SongEntity>[];
    for (final song in sorted) {
      if (result.length >= maxCount) break;
      final key = song.artist.toLowerCase();
      final count = byArtistCount[key] ?? 0;
      if (count >= 2) {
        continue;
      }
      byArtistCount[key] = count + 1;
      result.add(song);
    }

    // If artist cap removed too much, backfill from sorted to preserve fill guarantee.
    if (result.length < maxCount) {
      for (final song in sorted) {
        if (result.length >= maxCount) break;
        if (result.any((s) => s.id == song.id)) continue;
        result.add(song);
      }
    }

    return result;
  }

  bool _isSingleTrack(SongEntity song) {
    final title = song.title.toLowerCase();
    final artist = song.artist.toLowerCase();
    final duration = song.duration;

    if (_nonTrackTitlePattern.hasMatch(title) || _nonTrackTitlePattern.hasMatch(artist)) {
      return false;
    }

    // Keep typical single lengths only; blocks full sets and tiny clips.
    if (duration > Duration.zero && (duration < const Duration(seconds: 90) || duration > const Duration(minutes: 8))) {
      return false;
    }

    return true;
  }
}
