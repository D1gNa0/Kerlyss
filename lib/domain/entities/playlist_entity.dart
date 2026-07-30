class PlaylistEntity {
  final int? id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final bool isRealtimeSynced;
  final bool autoDownloadNewTracks;
  final String? spotifySourceUrl;
  final String? coverArtUrl;
  final DateTime? lastSyncedAt;

  PlaylistEntity({
    this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.isRealtimeSynced = false,
    this.autoDownloadNewTracks = false,
    this.spotifySourceUrl,
    this.coverArtUrl,
    this.lastSyncedAt,
  });

  PlaylistEntity copyWith({
    int? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    bool? isRealtimeSynced,
    bool? autoDownloadNewTracks,
    String? spotifySourceUrl,
    String? coverArtUrl,
    DateTime? lastSyncedAt,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      isRealtimeSynced: isRealtimeSynced ?? this.isRealtimeSynced,
      autoDownloadNewTracks: autoDownloadNewTracks ?? this.autoDownloadNewTracks,
      spotifySourceUrl: spotifySourceUrl ?? this.spotifySourceUrl,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
