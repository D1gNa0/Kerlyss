class PlaylistEntity {
  final int? id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;

  PlaylistEntity({
    this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
  });

  PlaylistEntity copyWith({
    int? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
  }) {
    return PlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
