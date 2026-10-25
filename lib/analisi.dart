// Analisi delle caselle in corso: un solo controllore per tutta l'app, così prosegue cambiando schermata.
import 'package:flutter/foundation.dart';

import 'archivio.dart';
import 'credenziali.dart';
import 'posta.dart';

class Analisi extends ChangeNotifier {
  Analisi._();
  static final istanza = Analisi._();

  bool inCorso = false;
  String testo = '';
  double frazione = 0;
  bool _ferma = false;
  List<String> errori = [];
  int ultimeNuove = 0;
  int giri = 0; // aumenta a ogni analisi finita: le schermate ricaricano i dati

  void ferma() {
    _ferma = true;
    testo = 'Mi fermo…';
    notifyListeners();
  }

  Future<void> avvia(List<Casella> caselle) async {
    if (inCorso || caselle.isEmpty) return;
    inCorso = true;
    _ferma = false;
    errori = [];
    ultimeNuove = 0;
    frazione = 0;
    testo = 'Avvio dell\'analisi…';
    notifyListeners();
    final archivio = await Archivio.apri();
    for (var i = 0; i < caselle.length; i++) {
      if (_ferma) break;
      final c = caselle[i];
      testo = '${c.email}: collegamento…';
      frazione = i / caselle.length;
      notifyListeners();
      try {
        final segreto = await leggiSegreto(c.email);
        if (segreto == null) throw Exception('credenziali non trovate: togli la casella e aggiungila di nuovo');
        final client = await collega(c.host, c.port, c.email, segreto, oauth: c.auth == 'oauth_ms');
        try {
          ultimeNuove += await analizza(client, archivio, c.id, avanzamento: (t, f) {
            testo = '${c.email} · $t';
            frazione = (i + f) / caselle.length;
            notifyListeners();
          }, fermati: () => _ferma);
        } finally {
          try {
            await client.logout();
            await client.disconnect();
          } catch (_) {}
        }
        await archivio.segnaAnalisi(c.id, DateTime.now().millisecondsSinceEpoch / 1000, '');
      } on InterruptedException {
        break;
      } on AccessoNegato catch (e) {
        await archivio.segnaAnalisi(c.id, c.ultimaAnalisi, 'accesso rifiutato: $e');
        errori.add('${c.email}: accesso rifiutato: $e');
      } catch (e) {
        final m = '$e'.replaceFirst('Exception: ', '');
        await archivio.segnaAnalisi(c.id, c.ultimaAnalisi, m);
        errori.add('${c.email}: $m');
      }
    }
    inCorso = false;
    giri++;
    testo = '';
    notifyListeners();
  }
}
