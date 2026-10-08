import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// AES-256-GCM + PBKDF2 helpers (pure Dart, works in background isolates).
class Crypto {
  Crypto._();

  static final Random _rng = Random.secure();

  static Uint8List randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

  static Uint8List pbkdf2(String secret, Uint8List salt, {int iterations = 120000}) {
    final d = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, 32));
    return d.process(Uint8List.fromList(utf8.encode(secret)));
  }

  static GCMBlockCipher _gcm(bool encrypt, Uint8List key, Uint8List nonce, [Uint8List? aad]) =>
      GCMBlockCipher(AESEngine())
        ..init(encrypt, AEADParameters(KeyParameter(key), 128, nonce, aad ?? Uint8List(0)));

  /// Returns nonce(12) || ciphertext || tag(16).
  static Uint8List seal(Uint8List key, Uint8List plain, {Uint8List? aad}) {
    final nonce = randomBytes(12);
    final ct = _gcm(true, key, nonce, aad).process(plain);
    return Uint8List.fromList([...nonce, ...ct]);
  }

  /// Throws [InvalidCipherTextException] on wrong key / tampering.
  static Uint8List open(Uint8List key, Uint8List sealed, {Uint8List? aad}) {
    if (sealed.length < 28) throw const FormatException('Data too short');
    final nonce = Uint8List.sublistView(sealed, 0, 12);
    final ct = Uint8List.sublistView(sealed, 12);
    return _gcm(false, key, nonce, aad).process(ct);
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a[i] ^ b[i];
    }
    return r == 0;
  }
}

/// Streaming encrypted container used for backups.
///
/// File layout:
///   "GVB1" | salt(16) | iterations(u32) | chunk*
///   chunk = length(u32) | AES-GCM(nonce|ct|tag) of up to 1 MiB plaintext
/// The chunk index is bound as AAD so chunks can't be reordered; the last
/// chunk is flagged so truncation is detected.
class EncryptedWriter {
  EncryptedWriter._(this._sink, this._key);

  static const chunkSize = 1 << 20;
  static final magic = ascii.encode('GVB1');

  final IOSink _sink;
  final Uint8List _key;
  final BytesBuilder _buf = BytesBuilder(copy: false);
  int _index = 0;

  static Future<EncryptedWriter> create(File file, String passphrase,
      {int iterations = 120000}) async {
    final salt = Crypto.randomBytes(16);
    final key = Crypto.pbkdf2(passphrase, salt, iterations: iterations);
    final sink = file.openWrite();
    final header = ByteData(4)..setUint32(0, iterations);
    sink
      ..add(magic)
      ..add(salt)
      ..add(header.buffer.asUint8List());
    return EncryptedWriter._(sink, key);
  }

  void add(List<int> data) {
    _buf.add(data);
    while (_buf.length >= chunkSize) {
      final all = _buf.takeBytes();
      _emit(Uint8List.sublistView(all, 0, chunkSize), last: false);
      if (all.length > chunkSize) _buf.add(Uint8List.sublistView(all, chunkSize));
    }
  }

  void _emit(Uint8List plain, {required bool last}) {
    final aad = ByteData(5)
      ..setUint32(0, _index++)
      ..setUint8(4, last ? 1 : 0);
    final sealed = Crypto.seal(_key, plain, aad: aad.buffer.asUint8List());
    final len = ByteData(4)..setUint32(0, sealed.length);
    _sink
      ..add(len.buffer.asUint8List())
      ..add(sealed);
  }

  Future<void> close() async {
    _emit(_buf.takeBytes(), last: true);
    await _sink.flush();
    await _sink.close();
  }
}

/// Reads an [EncryptedWriter] file back, chunk by chunk.
class EncryptedReader {
  EncryptedReader._(this._raf, this._key);

  final RandomAccessFile _raf;
  final Uint8List _key;
  int _index = 0;
  bool _sawLast = false;
  Uint8List _pending = Uint8List(0);
  int _pos = 0;

  static Future<EncryptedReader> open(File file, String passphrase) async {
    final raf = await file.open();
    final head = await raf.read(24);
    if (head.length < 24 || ascii.decode(head.sublist(0, 4), allowInvalid: true) != 'GVB1') {
      await raf.close();
      throw const FormatException('Not a GoldVault backup file');
    }
    final salt = Uint8List.fromList(head.sublist(4, 20));
    final iterations = ByteData.sublistView(Uint8List.fromList(head), 20, 24).getUint32(0);
    final key = Crypto.pbkdf2(passphrase, salt, iterations: iterations);
    return EncryptedReader._(raf, key);
  }

  Future<bool> _nextChunk() async {
    if (_sawLast) return false;
    final lenBytes = await _raf.read(4);
    if (lenBytes.length < 4) throw const FormatException('Backup file is truncated');
    final len = ByteData.sublistView(Uint8List.fromList(lenBytes)).getUint32(0);
    final sealed = await _raf.read(len);
    if (sealed.length < len) throw const FormatException('Backup file is truncated');
    // Try "not last" first, then "last".
    for (final last in [false, true]) {
      final aad = ByteData(5)
        ..setUint32(0, _index)
        ..setUint8(4, last ? 1 : 0);
      try {
        _pending = Crypto.open(_key, sealed, aad: aad.buffer.asUint8List());
        _pos = 0;
        _index++;
        _sawLast = last;
        return true;
      } on InvalidCipherTextException {
        if (last) rethrow;
      } on ArgumentError {
        if (last) rethrow;
      }
    }
    return false;
  }

  /// Reads exactly [n] bytes, or throws if the stream ends early.
  Future<Uint8List> read(int n) async {
    final out = BytesBuilder(copy: false);
    var need = n;
    while (need > 0) {
      if (_pos >= _pending.length) {
        if (!await _nextChunk()) throw const FormatException('Unexpected end of backup');
        continue;
      }
      final take = min(need, _pending.length - _pos);
      out.add(Uint8List.sublistView(_pending, _pos, _pos + take));
      _pos += take;
      need -= take;
    }
    return out.takeBytes();
  }

  /// True when every byte has been consumed and the final chunk was seen.
  Future<bool> atEnd() async {
    while (_pos >= _pending.length) {
      if (!await _nextChunk()) return true;
    }
    return false;
  }

  Future<void> close() => _raf.close();
}
