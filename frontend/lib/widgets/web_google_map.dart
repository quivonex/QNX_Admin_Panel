/*
// 📍 File: lib/widgets/web_google_map.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class WebGoogleMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final Function(double, double)? onTap;

  const WebGoogleMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 14,
    this.onTap,
  });

  @override
  State<WebGoogleMap> createState() => _WebGoogleMapState();
}

class _WebGoogleMapState extends State<WebGoogleMap> {
  late String _iframeUrl;

  @override
  void initState() {
    super.initState();
    _updateIframeUrl();
  }

  void _updateIframeUrl() {
    _iframeUrl =
    'https://www.google.com/maps/embed/v1/place'
        '?key=AIzaSyAtuIRCXUATyplH9aMH3d7lPwmpK5tT5To'
        '&q=${widget.latitude},${widget.longitude}'
        '&zoom=${widget.zoom}';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: iframe(
        src: _iframeUrl,
        width: '100%',
        height: '100%',
        style: const {
          'border': '0',
          'allowfullscreen': '',
          'loading': 'lazy',
        },
      ),
    );
  }

  // ✅ iframe widget (web only)
  @visibleForTesting
  Widget iframe({
    required String src,
    required String width,
    required String height,
    Map<String, String>? style,
  }) {

    // Web only - using html package
    // ignore: undefined_prefixed_name
    return ui.platformViewRegistry.registerViewFactory(
      'google-maps-iframe',
          (int viewId) {
        final iframe = html.IFrameElement()
          ..src = src
          ..style.width = width
          ..style.height = height
          ..style.border = style?['border'] ?? '0'
          ..setAttribute('allowfullscreen', 'true')
          ..setAttribute('loading', 'lazy');
        return iframe;
      },
    );
  }
}
x`
*/
