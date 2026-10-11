import 'package:flutter/services.dart';

/// Lê automaticamente as fotos da pasta `assets/trabalhos/`.
/// Para adicionar um trabalho novo, basta colocar a foto nessa pasta.
class WorksService {
  WorksService._();

  static const folder = 'assets/trabalhos/';
  static const _extensions = ['.jpg', '.jpeg', '.png', '.webp'];

  static Future<List<String>> loadPhotos() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final photos = manifest
        .listAssets()
        .where((path) =>
            path.startsWith(folder) &&
            _extensions.any((e) => path.toLowerCase().endsWith(e)))
        .toList()
      ..sort();
    return photos;
  }
}
