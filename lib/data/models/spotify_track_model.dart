class SpotifyTrackModel {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String artworkUrl;

  SpotifyTrackModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.artworkUrl,
  });

  factory SpotifyTrackModel.fromJson(Map<String, dynamic> json) {
    return SpotifyTrackModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      artworkUrl: json['artworkUrl'] ?? '',
    );
  }
}
