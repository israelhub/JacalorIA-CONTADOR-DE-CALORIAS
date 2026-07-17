import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Resultado da otimizacao: bytes prontos para envio/armazenamento + mime type.
class OptimizedImage {
  const OptimizedImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

// Maior lado da imagem apos redimensionar. 1280px e suficiente para a IA
// identificar os alimentos e mantem o payload pequeno.
const int _maxDimension = 1280;
const int _jpegQuality = 80;

/// Redimensiona (limitando o maior lado a [_maxDimension]) e recomprime como
/// JPEG. Reduz muito o tamanho enviado para analise, o uso de memoria do
/// backend e o tempo para a imagem aparecer na tela e na listagem.
///
/// Roda o trabalho pesado fora da UI thread via [compute]. Em caso de falha,
/// devolve os bytes originais para nao bloquear o fluxo do usuario.
Future<OptimizedImage> optimizeForAnalysis(Uint8List original) async {
  try {
    final bytes = await compute(_resizeAndEncode, original);
    return OptimizedImage(bytes: bytes, mimeType: 'image/jpeg');
  } catch (_) {
    return OptimizedImage(bytes: original, mimeType: 'image/jpeg');
  }
}

Uint8List _resizeAndEncode(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    return input;
  }

  final bool isLandscape = decoded.width >= decoded.height;
  final int longestSide = isLandscape ? decoded.width : decoded.height;

  final img.Image normalized = longestSide > _maxDimension
      ? (isLandscape
            ? img.copyResize(decoded, width: _maxDimension)
            : img.copyResize(decoded, height: _maxDimension))
      : decoded;

  return img.encodeJpg(normalized, quality: _jpegQuality);
}
