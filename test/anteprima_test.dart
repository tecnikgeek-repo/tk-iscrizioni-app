// Anteprime delle schermate (390×844, caratteri veri) salvate in build/anteprime/, per controllarle senza telefono.
// Uso: flutter test test/anteprima_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkiscrizioni/aggiungi.dart';
import 'package:tkiscrizioni/archivio.dart';
import 'package:tkiscrizioni/servizio.dart';
import 'package:tkiscrizioni/tema.dart';

import 'caratteri.dart';

Future<void> _scatta(WidgetTester t, Widget schermata, String nome, {Future<void> Function()? prima}) async {
  final chiave = GlobalKey();
  await t.pumpWidget(RepaintBoundary(
    key: chiave,
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: temaKit(), home: schermata),
  ));
  await t.pump(const Duration(milliseconds: 300));
  if (prima != null) await prima();
  await t.pump(const Duration(milliseconds: 300));
  await t.runAsync(() async {
    final img = await (chiave.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/anteprime').createSync(recursive: true);
    File('build/anteprime/$nome.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    configTk = configIscrizioni;
    await caricaCaratteri();
  });

  testWidgets('anteprime', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    await _scatta(t, const SchermataAggiungi(), 'aggiungi-vuota');
    await _scatta(t, const SchermataAggiungi(), 'aggiungi-gmail', prima: () async {
      await t.enterText(find.byType(TextField).first, 'mario.rossi@gmail.com');
    });
    await _scatta(t, const SchermataAggiungi(), 'aggiungi-outlook', prima: () async {
      await t.enterText(find.byType(TextField).first, 'mario.rossi@hotmail.it');
    });
    await _scatta(t, const SchermataAggiungi(), 'aggiungi-altro', prima: () async {
      await t.enterText(find.byType(TextField).first, 'info@miaditta.it');
    });
    final s = Servizio(
      dominio: 'zalando.it', nome: 'Zalando', n: 42, prima: 1656662400, ultima: 1781000000, acc: 1, sic: 0,
      acq: 3, lst: 38, caselle: [1], cat: 'newsletter',
      disiscrizione: '<https://zalando.example/u>', unClic: true, stato: 'cancellare', nota: '',
    );
    await _scatta(t, SchermataServizio(servizio: s, caselle: const {1: 'mario.rossi@gmail.com'}), 'servizio');
  });
}
