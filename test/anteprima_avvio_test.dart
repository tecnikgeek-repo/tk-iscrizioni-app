// Anteprime dello splash e della prima schermata (caratteri veri) in build/anteprime/, senza telefono.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkiscrizioni/tema.dart';

import 'caratteri.dart';

Future<void> _scatta(WidgetTester t, Widget w, String nome) async {
  final k = GlobalKey();
  await t.pumpWidget(RepaintBoundary(key: k, child: MaterialApp(debugShowCheckedModeBanner: false, theme: temaKit(), home: w)));
  await t.pump(const Duration(milliseconds: 500));
  await t.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final img = await (k.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/anteprime').createSync(recursive: true);
    File('build/anteprime/$nome.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
  await t.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    configTk = configIscrizioni;
    await caricaCaratteri();
  });

  testWidgets('anteprime', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    await _scatta(t, const SchermataAvvio(), 'avvio');
    await _scatta(t, const SchermataInformazioni(), 'info');
    await t.pumpWidget(const SizedBox());
  });
}
