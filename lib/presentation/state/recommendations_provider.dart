import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/audio_source_type.dart';
import '../../data/repositories/repository_providers.dart';
import 'library_provider.dart';
import 'download_state_provider.dart';

class RecommendationState {
  final List<SongEntity> similarSongs;
  final List<SongEntity> trendingSongs;
  final String? baseIdeaArtist;
  final bool isLoading;

  RecommendationState({
    required this.similarSongs,
    required this.trendingSongs,
    this.baseIdeaArtist,
    this.isLoading = false,
  });

  RecommendationState copyWith({
    List<SongEntity>? similarSongs,
    List<SongEntity>? trendingSongs,
    String? baseIdeaArtist,
    bool? isLoading,
  }) {
    return RecommendationState(
      similarSongs: similarSongs ?? this.similarSongs,
      trendingSongs: trendingSongs ?? this.trendingSongs,
      baseIdeaArtist: baseIdeaArtist ?? this.baseIdeaArtist,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final recommendationsProvider = StateNotifierProvider<RecommendationsNotifier, RecommendationState>((ref) {
  final youtubeService = ref.watch(youtubeServiceProvider);
  return RecommendationsNotifier(ref, youtubeService);
});

class RecommendationsNotifier extends StateNotifier<RecommendationState> {
  final Ref _ref;
  final dynamic _youtubeService;
  bool _hasFetched = false;

  RecommendationsNotifier(this._ref, this._youtubeService)
      : super(RecommendationState(similarSongs: [], trendingSongs: [], isLoading: false));

  Future<void> fetchRecommendations() async {
    if (_hasFetched || state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final library = _ref.read(libraryProvider).allSongs;
      final favoriteIds = _ref.read(libraryProvider).favoriteSongs.map((s) => s.id).toSet();
      final downloadedIds = _ref.read(downloadStateProvider).alreadyDownloadedIds;
      
      List<SongEntity> similar = [];
      List<SongEntity> trending = [];
      String? ideaArtist;

      // Fetch Trending
      final trendingVideos = await _youtubeService.getTrendingMusic();
        trending = trendingVideos
          .map<SongEntity>((vid) => _mapVideoToEntity(vid))
          .where((song) => !favoriteIds.contains(song.id) && !downloadedIds.contains(song.id))
          .toList();

      // Fetch Similar if library has songs
      if (library.isNotEmpty) {
        // Pick a completely random song from their library
        final randomSong = library[Random().nextInt(library.length)];
        ideaArtist = randomSong.artist;
        
        // Use YouTube ID if it came from YouTube
        String lookupId = randomSong.id;
        if (lookupId.startsWith('jamendo_')) {
          // If jamendo, perform a generic text search on Youtube for that artist
          final artistVideos = await _youtubeService.searchVideos('${randomSong.artist} mix');
          similar = artistVideos.map<SongEntity>((vid) => _mapVideoToEntity(vid)).toList();
        } else {
          // It's likely a youtube ID, ask for related videos
          final relatedVideos = await _youtubeService.getRelatedVideos(lookupId);
          similar = relatedVideos.map<SongEntity>((vid) => _mapVideoToEntity(vid)).toList();
        }
      } else {
        ideaArtist = null;
      }

      _hasFetched = true;
      if (mounted) {
        state = state.copyWith(
          similarSongs: similar,
          trendingSongs: trending,
          baseIdeaArtist: ideaArtist,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void refresh() {
    _hasFetched = false;
    fetchRecommendations();
  }

  SongEntity _mapVideoToEntity(dynamic video) {
    return SongEntity(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      album: 'YouTube',
      albumArtUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
      sourceUrl: video.url,
      sourceType: AudioSourceType.youtube,
      dateAdded: DateTime.now(),
    );
  }
}
