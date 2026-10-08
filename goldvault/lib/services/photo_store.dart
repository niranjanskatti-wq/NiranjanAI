import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../core/crypto.dart';

/// Stores photos AES-GCM encrypted inside the app's private folder.
/// Files are referenced from the database by their bare file name.
class PhotoStore {
  PhotoStore(this.dir, this._key);

  final Directory dir;
  Uint8List _key;
  final _cache = <String, Uint8List>{}; // insertion-ordered (LRU)
  static const _cacheMax = 60;

  /// The key photos are encrypted with (stored in backups).
  Uint8List get key => _key;

  void setKey(Uint8List key) {
    _key = key;
    _cache.clear();
  }

  File fileFor(String name) => File(p.join(dir.path, name));

  Future<String> save(Uint8List bytes) async {
    await dir.create(recursive: true);
    final name = '${DateTime.now().microsecondsSinceEpoch}_${_rand()}.gvp';
    await fileFor(name).writeAsBytes(Crypto.seal(_key, bytes), flush: true);
    _put(name, bytes);
    return name;
  }

  Future<Uint8List?> load(String name) async {
    final hit = _cache.remove(name);
    if (hit != null) {
      _cache[name] = hit;
      return hit;
    }
    final f = fileFor(name);
    if (!await f.exists()) return null;
    try {
      final b = Crypto.open(_key, await f.readAsBytes());
      _put(name, b);
      return b;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String name) async {
    _cache.remove(name);
    final f = fileFor(name);
    if (await f.exists()) await f.delete();
  }

  Future<List<File>> allFiles() async {
    if (!await dir.exists()) return [];
    return dir.listSync().whereType<File>().where((f) => f.path.endsWith('.gvp')).toList();
  }

  void _put(String k, Uint8List v) {
    _cache[k] = v;
    while (_cache.length > _cacheMax) {
      _cache.remove(_cache.keys.first);
    }
  }

  static String _rand() =>
      Crypto.randomBytes(4).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
