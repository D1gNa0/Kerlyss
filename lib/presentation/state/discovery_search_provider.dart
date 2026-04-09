import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/song_repository.dart';
import '../../data/repositories/repository_providers.dart';

// State definition
class DiscoverySearchState {
  final String query;
  final bool isLoading;
  final List<SongEntity> results;
  final String? error;

  const DiscoverySearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  DiscoverySearchState copyWith({
    String? query,
    bool? isLoading,
    List<SongEntity>? results,
    String? error,
  }) {
    return DiscoverySearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error, // Allow nulling out the error
    );
  }
}

// StateNotifier definition
class DiscoverySearchNotifier extends StateNotifier<DiscoverySearchState> {
  final SongRepository _repository;
  Timer? _debounce;

  DiscoverySearchNotifier(this._repository) : super(const DiscoverySearchState());

  void onSearchQueryChanged(String query) {
    // Cancel previous timer if the user types quickly
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      state = state.copyWith(query: '', isLoading: false, results: [], error: null);
      return;
    }

    state = state.copyWith(query: trimmedQuery, isLoading: true, error: null);

    // Apply 500ms debounce
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(trimmedQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _repository.searchSongs(query);
      
      // Ensure we don't update state if the user typed something else while waiting
      if (state.query == query && mounted) {
        state = state.copyWith(isLoading: false, results: results, error: null);
      }
    } catch (e) {
      if (state.query == query && mounted) {
        state = state.copyWith(isLoading: false, error: e.toString(), results: []);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// Provider exposure
final discoverySearchProvider =
    StateNotifierProvider<DiscoverySearchNotifier, DiscoverySearchState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  return DiscoverySearchNotifier(repository);
});
