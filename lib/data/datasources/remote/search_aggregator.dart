import '../../../domain/entities/song_entity.dart';
import 'deezer_public_service.dart';

class SearchAggregator {
  final DeezerPublicService _deezerService;

  SearchAggregator(this._deezerService);

  Future<List<SongEntity>> search(String query) async {
    return await _deezerService.searchTracks(query);
  }
}
