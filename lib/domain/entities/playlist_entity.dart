class PlaylistEntity {
  final int? id;
  final String? uuid;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isRealtimeSynced;
  final bool autoDownloadNewTracks;
  final String? spotifySourceUrl;
  final String? coverArtUrl;
  final DateTime? lastSyncedAt;

  PlaylistEntity({
    this.id,
    this.uuid,
    required this.name,
    required this.songIds,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.isRealtimeSynced = false,
    this.autoDownloadNewTracks = false,
    this.spotifySourceUrl,
    this.coverArtUrl,
    this.lastSyncedAt,
  });

  PlaylistEntity copyWith({
    int? id,
    String? uuid,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isRealtimeSynced,
    bool? autoDownloadNewTracks,
    String? spotifySourceUrl,
    String? coverArtUrl,
    DateTime? lastSyncedAt,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isRealtimeSynced: isRealtimeSynced ?? this.isRealtimeSynced,
      autoDownloadNewTracks: autoDownloadNewTracks ?? this.autoDownloadNewTracks,
      spotifySourceUrl: spotifySourceUrl ?? this.spotifySourceUrl,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
