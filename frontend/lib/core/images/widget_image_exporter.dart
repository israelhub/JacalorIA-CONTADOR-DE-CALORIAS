import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

/// Renders a [widget] off-screen with Flutter's text engine (full Unicode)
/// and returns image bytes. Prefer this over `package:image` bitmap fonts.
Future<Uint8List> exportWidgetToImageBytes({
  required Widget widget,
  required Size logicalSize,
  double pixelRatio = 2,
  bool asJpeg = true,
  int jpegQuality = 92,
}) async {
  final repaintBoundary = RenderRepaintBoundary();
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      physicalConstraints: BoxConstraints.tight(
        Size(
          logicalSize.width * pixelRatio,
          logicalSize.height * pixelRatio,
        ),
      ),
      logicalConstraints: BoxConstraints.tight(logicalSize),
      devicePixelRatio: pixelRatio,
    ),
  );

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(
          size: logicalSize,
          devicePixelRatio: pixelRatio,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: widget,
          ),
        ),
      ),
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  // Allow Google Fonts / deferred glyphs to settle.
  await Future<void>.delayed(const Duration(milliseconds: 80));
  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (byteData == null) {
    throw StateError('Falha ao renderizar o card de resultado.');
  }

  final pngBytes = byteData.buffer.asUint8List();
  if (!asJpeg) {
    return pngBytes;
  }

  final decoded = img.decodePng(pngBytes);
  if (decoded == null) {
    return pngBytes;
  }
  return Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality));
}
