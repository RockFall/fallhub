import 'dart:math';
import 'dart:typed_data';

/// Random-access bytes for streaming Timeline JSON without loading the file.
abstract class TimelineByteSource {
  int get length;
  Uint8List read(int offset, int length);
}

class Uint8ListTimelineByteSource implements TimelineByteSource {
  Uint8ListTimelineByteSource(this._bytes);

  final Uint8List _bytes;

  @override
  int get length => _bytes.length;

  @override
  Uint8List read(int offset, int length) {
    if (length <= 0 || offset >= _bytes.length) return Uint8List(0);
    final end = min(_bytes.length, offset + length);
    return Uint8List.sublistView(_bytes, offset, end);
  }
}

/// Sliding-window cursor. Structural JSON is ASCII, so skipping a 200 MB
/// `rawSignals` array never copies that array — only a 64 KB window moves.
class TimelineByteCursor {
  TimelineByteCursor(this.source, {this.windowSize = 65536});

  final TimelineByteSource source;
  final int windowSize;
  var pos = 0;
  Uint8List _buf = Uint8List(0);
  var _bufStart = 0;

  int get length => source.length;
  bool get isEof => pos >= length;

  void _fillWindow(int index) {
    if (index < 0 || index >= length) return;
    if (index >= _bufStart && index < _bufStart + _buf.length) return;
    _bufStart = index;
    final take = min(windowSize, length - index);
    _buf = source.read(index, take);
  }

  int byteAt(int index) {
    if (index < 0 || index >= length) return -1;
    _fillWindow(index);
    final local = index - _bufStart;
    if (local < 0 || local >= _buf.length) return -1;
    return _buf[local];
  }

  int peek() => byteAt(pos);

  int next() {
    final b = peek();
    if (b >= 0) pos++;
    return b;
  }

  void skipWs() {
    while (!isEof && _isWs(peek())) {
      pos++;
    }
  }

  void skipBom() {
    if (length >= 3 &&
        byteAt(0) == 0xEF &&
        byteAt(1) == 0xBB &&
        byteAt(2) == 0xBF) {
      pos = 3;
    }
  }

  void expectByte(int expected) {
    final got = next();
    if (got != expected) {
      throw FormatException(
        'JSON inválido: esperado ${String.fromCharCode(expected)}, '
        'obtido ${got < 0 ? 'EOF' : String.fromCharCode(got)}',
        null,
        pos - 1,
      );
    }
  }

  /// Copies [start, end) — used only for one semantic field / path point.
  Uint8List slice(int start, int end) {
    if (end <= start) return Uint8List(0);
    return source.read(start, end - start);
  }

  /// Advances past a JSON value. Does not allocate the value.
  void skipValue() {
    skipWs();
    if (isEof) {
      throw const FormatException('JSON truncado');
    }
    final c = peek();
    if (c == 0x22) {
      _skipString();
      return;
    }
    if (c == 0x7B || c == 0x5B) {
      _skipContainer();
      return;
    }
    while (!isEof) {
      final ch = peek();
      if (ch == 0x2C || ch == 0x7D || ch == 0x5D || _isWs(ch)) break;
      pos++;
    }
  }

  /// Scans `{...}` / `[...]` a window at a time so a 200 MB array is O(n)
  /// over 64 KB chunks, not a Dart call per byte and not a copy of the array.
  void _skipContainer() {
    final first = next();
    final stack = <int>[first];
    var inStr = false;
    var escaped = false;
    while (stack.isNotEmpty && !isEof) {
      _fillWindow(pos);
      if (pos < _bufStart || pos >= _bufStart + _buf.length) {
        throw const FormatException('JSON truncado');
      }
      final buf = _buf;
      final bufStart = _bufStart;
      var i = pos - bufStart;
      while (i < buf.length && stack.isNotEmpty) {
        final ch = buf[i];
        i++;
        if (inStr) {
          if (escaped) {
            escaped = false;
          } else if (ch == 0x5C) {
            escaped = true;
          } else if (ch == 0x22) {
            inStr = false;
          }
          continue;
        }
        if (ch == 0x22) {
          inStr = true;
          continue;
        }
        if (ch == 0x7B || ch == 0x5B) {
          stack.add(ch);
        } else if (ch == 0x7D) {
          if (stack.last != 0x7B) {
            pos = bufStart + i;
            throw const FormatException('JSON inválido: chaves desalinhadas');
          }
          stack.removeLast();
        } else if (ch == 0x5D) {
          if (stack.last != 0x5B) {
            pos = bufStart + i;
            throw const FormatException(
              'JSON inválido: colchetes desalinhados',
            );
          }
          stack.removeLast();
        }
      }
      pos = bufStart + i;
    }
    if (stack.isNotEmpty) {
      throw const FormatException('JSON truncado');
    }
  }

  String readString() {
    skipWs();
    expectByte(0x22);
    final start = pos;
    _skipStringBody();
    final bytes = slice(start, pos - 1);
    return _decodeJsonStringBytes(bytes);
  }

  void _skipString() {
    expectByte(0x22);
    _skipStringBody();
  }

  void _skipStringBody() {
    var escaped = false;
    while (!isEof) {
      _fillWindow(pos);
      if (pos < _bufStart || pos >= _bufStart + _buf.length) {
        throw const FormatException('JSON truncado: string sem fecho');
      }
      final buf = _buf;
      final bufStart = _bufStart;
      var i = pos - bufStart;
      while (i < buf.length) {
        final ch = buf[i];
        i++;
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == 0x5C) {
          escaped = true;
          continue;
        }
        if (ch == 0x22) {
          pos = bufStart + i;
          return;
        }
      }
      pos = bufStart + i;
    }
    throw const FormatException('JSON truncado: string sem fecho');
  }

  static bool _isWs(int code) =>
      code == 0x20 || code == 0x09 || code == 0x0A || code == 0x0D;

  /// Keys we care about are ASCII; still decode UTF-8 for completeness.
  static String _decodeJsonStringBytes(Uint8List bytes) {
    final out = StringBuffer();
    var i = 0;
    while (i < bytes.length) {
      final b = bytes[i];
      if (b == 0x5C && i + 1 < bytes.length) {
        final n = bytes[i + 1];
        i += 2;
        switch (n) {
          case 0x22:
            out.write('"');
          case 0x5C:
            out.write(r'\');
          case 0x2F:
            out.write('/');
          case 0x62:
            out.write('\b');
          case 0x66:
            out.write('\f');
          case 0x6E:
            out.write('\n');
          case 0x72:
            out.write('\r');
          case 0x74:
            out.write('\t');
          case 0x75:
            if (i + 4 <= bytes.length) {
              final hex = String.fromCharCodes(bytes.sublist(i, i + 4));
              out.writeCharCode(int.parse(hex, radix: 16));
              i += 4;
            }
          default:
            out.writeCharCode(n);
        }
        continue;
      }
      // UTF-8 sequence.
      if (b < 0x80) {
        out.writeCharCode(b);
        i++;
      } else if (b < 0xE0 && i + 1 < bytes.length) {
        out.writeCharCode(((b & 0x1F) << 6) | (bytes[i + 1] & 0x3F));
        i += 2;
      } else if (b < 0xF0 && i + 2 < bytes.length) {
        out.writeCharCode(
          ((b & 0x0F) << 12) |
              ((bytes[i + 1] & 0x3F) << 6) |
              (bytes[i + 2] & 0x3F),
        );
        i += 3;
      } else if (i + 3 < bytes.length) {
        out.writeCharCode(
          ((b & 0x07) << 18) |
              ((bytes[i + 1] & 0x3F) << 12) |
              ((bytes[i + 2] & 0x3F) << 6) |
              (bytes[i + 3] & 0x3F),
        );
        i += 4;
      } else {
        i++;
      }
    }
    return out.toString();
  }
}
