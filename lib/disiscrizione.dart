// Disiscrizione in un clic (RFC 8058): POST al link del mittente, con i controlli sul link (come disiscrizione.py
// del programma per computer). Solo https verso indirizzi pubblici di internet: niente http, niente reti locali
// (router, stampanti, servizi del telefono), e lo stesso vale per ogni redirect. Nessun cookie, nessun dato.
import 'dart:io';

import 'package:http/http.dart' as http;

const maxRedirect = 3;

class LinkNonAmmesso implements Exception {
  LinkNonAmmesso(this.messaggio);
  final String messaggio;
  @override
  String toString() => messaggio;
}

/// Vero se l'indirizzo è di internet: non locale, non privato, non riservato.
bool indirizzoPubblico(InternetAddress ip) {
  var b = ip.rawAddress;
  if (ip.type == InternetAddressType.IPv6) {
    // ::ffff:a.b.c.d = indirizzo IPv4 scritto in IPv6
    final mappato = b.length == 16 && b.sublist(0, 10).every((x) => x == 0) && b[10] == 0xff && b[11] == 0xff;
    if (mappato) {
      b = b.sublist(12);
    } else {
      if (b.length != 16) return false;
      if (b.every((x) => x == 0)) return false; // :: e ::1
      if (b.sublist(0, 15).every((x) => x == 0)) return false;
      if ((b[0] & 0xfe) == 0xfc) return false; // fc00::/7 rete locale
      if (b[0] == 0xfe && (b[1] & 0xc0) == 0x80) return false; // fe80::/10 collegamento locale
      if (b[0] == 0xff) return false; // multicast
      if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) return false; // 2001:db8::/32 esempi
      if (b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xff && b[3] == 0x9b) return false; // 64:ff9b:: traduzione
      return (b[0] & 0xe0) == 0x20; // solo 2000::/3 è internet
    }
  }
  if (b.length != 4) return false;
  final (a, c) = (b[0], b[1]);
  if (a == 0 || a == 10 || a == 127) return false;
  if (a == 100 && (c & 0xc0) == 64) return false; // 100.64/10 operatore
  if (a == 169 && c == 254) return false; // collegamento locale
  if (a == 172 && (c & 0xf0) == 16) return false;
  if (a == 192 && c == 168) return false;
  if (a == 192 && c == 0 && (b[2] == 0 || b[2] == 2)) return false;
  if (a == 198 && (c == 18 || c == 19)) return false; // prove
  if (a == 198 && c == 51 && b[2] == 100) return false;
  if (a == 203 && c == 0 && b[2] == 113) return false;
  if (a >= 224) return false; // multicast e riservati
  return true;
}

/// Vero se il nome (o l'indirizzo) porta solo a indirizzi pubblici di internet.
Future<bool> hostPubblico(String host) async {
  host = host.trim();
  if (host.startsWith('[') && host.endsWith(']')) host = host.substring(1, host.length - 1);
  if (host.isEmpty) return false;
  final diretto = InternetAddress.tryParse(host.split('%').first);
  List<InternetAddress> indirizzi;
  if (diretto != null) {
    indirizzi = [diretto];
  } else {
    try {
      indirizzi = await InternetAddress.lookup(host).timeout(const Duration(seconds: 10));
    } catch (_) {
      return false;
    }
  }
  return indirizzi.isNotEmpty && indirizzi.every(indirizzoPubblico);
}

/// https, con un host, che porta a un indirizzo pubblico.
Future<bool> urlAmmesso(String url, {Future<bool> Function(String host) consenti = hostPubblico}) async {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme.toLowerCase() != 'https' || u.host.isEmpty) return false;
  return consenti(u.host);
}

String _host(String url) => Uri.tryParse(url)?.host ?? url;

/// Manda «List-Unsubscribe=One-Click». Ritorna il codice HTTP; solleva [LinkNonAmmesso] o l'errore di rete.
/// I redirect si seguono a mano (al massimo [maxRedirect]) e solo se anche la nuova destinazione è ammessa.
Future<int> inviaDisiscrizione(String url,
    {http.Client? client,
    Future<bool> Function(String host) consenti = hostPubblico,
    String versione = '',
    Duration timeout = const Duration(seconds: 20)}) async {
  final c = client ?? http.Client();
  try {
    var dove = url;
    for (var giro = 0;; giro++) {
      if (!await urlAmmesso(dove, consenti: consenti)) {
        throw LinkNonAmmesso(giro == 0
            ? 'il link non è sicuro (${_host(dove)}): serve https verso un sito pubblico'
            : 'il mittente rimanda a un indirizzo non sicuro (${_host(dove)})');
      }
      final richiesta = http.Request('POST', Uri.parse(dove))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
        ..headers['User-Agent'] = 'tk-iscrizioni/$versione'
        ..body = 'List-Unsubscribe=One-Click';
      final r = await c.send(richiesta).timeout(timeout);
      await r.stream.drain<void>();
      final verso = r.headers['location'];
      if (r.statusCode >= 300 && r.statusCode < 400 && verso != null && verso.isNotEmpty) {
        if (giro >= maxRedirect) throw LinkNonAmmesso('troppi rimandi del mittente');
        dove = Uri.parse(dove).resolve(verso).toString();
        continue;
      }
      return r.statusCode;
    }
  } finally {
    if (client == null) c.close();
  }
}
