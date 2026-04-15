class SpotifyPlaylistModel {
  final String name;
  final List<String> trackQueries; // "Track Name - Artist"

  SpotifyPlaylistModel({
    required this.name,
    required this.trackQueries,
  });
}
