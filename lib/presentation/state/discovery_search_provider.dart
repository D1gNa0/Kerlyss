import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';
import '../../core/services/stream_resolution_cache.dart';

enum SearchMode {
  songs,
  spotifyImport,
}

class DiscoverySearchState {
  final String query;
  final bool isLoading;
  final List<SongEntity> results;
  final String? error;
  final SearchMode searchMode;
  final bool downloadOnImport;

  const DiscoverySearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
    this.searchMode = SearchMode.songs,
    this.downloadOnImport = false,
  });

  DiscoverySearchState copyWith({
    String? query,
    bool? isLoading,
    List<SongEntity>? results,
    String? error,
    SearchMode? searchMode,
    bool? downloadOnImport,
  }) {
    return DiscoverySearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error, // Allow nulling out the error
      searchMode: searchMode ?? this.searchMode,
      downloadOnImport: downloadOnImport ?? this.downloadOnImport,
    );
  }
}

class DiscoverySearchNotifier extends StateNotifier<DiscoverySearchState> {
  final SongRepository _repository;
  Timer? _debounce;

  DiscoverySearchNotifier(this._repository) : super(const DiscoverySearchState());

  void toggleSearchMode() {
    final nextMode = state.searchMode == SearchMode.songs ? SearchMode.spotifyImport : SearchMode.songs;
    setSearchMode(nextMode);
  }

  void setSearchMode(SearchMode mode) {
    if (state.searchMode != mode) {
      state = state.copyWith(searchMode: mode, query: '', results: [], error: null);
    }
  }

  void toggleDownloadOnImport(bool value) {
    state = state.copyWith(downloadOnImport: value);
  }

  void onSearchQueryChanged(String query) {
    if (state.searchMode == SearchMode.spotifyImport) {
      // In import mode, we do not auto-search as they type. They must press an explicit import button
      // since the process is heavy and requires parsing a whole playlist.
      state = state.copyWith(query: query.trim());
      return;
    }

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      state = state.copyWith(query: '', isLoading: false, results: [], error: null);
      return;
    }

    state = state.copyWith(query: trimmedQuery, isLoading: true, error: null);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(trimmedQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _repository.searchSongs(query);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, results: results);
      // Fire-and-forget: pre-resolve YouTube IDs for the top results in the background
      StreamResolutionCache.instance.prefetch(results, _repository);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        results: [],
        error: 'Failed to search: \${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final discoverySearchProvider =
    StateNotifierProvider<DiscoverySearchNotifier, DiscoverySearchState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  return DiscoverySearchNotifier(repository);
});
