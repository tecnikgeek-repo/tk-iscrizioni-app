// Lettura della casella via IMAP: solo le intestazioni, in sola lettura (EXAMINE + BODY.PEEK).
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';

import 'archivio.dart';
import 'classifica.dart';

// AUTHENTICATION-RESULTS: l'esito della verifica DKIM scritto dal server di posta (serve per fidarsi del link di
// disiscrizione, vedi [rigaDaMessaggio])
const campiIntestazioni = 'FROM SUBJECT DATE LIST-UNSUBSCRIBE LIST-UNSUBSCRIBE-POST LIST-ID AUTHENTICATION-RESULTS';
const _blocco = 300;
final _nomiDaSaltare = RegExp(
    r'(^|/|\.)(sent|inviat|bozze|draft|cestino|trash|deleted|eliminat|spam|junk|posta indesiderata|indesiderat|'
    r'outbox|in uscita|posta inviata)',
    caseSensitive: false);

class AccessoNegato implements Exception {
  AccessoNegato(this.messaggio);
  final String messaggio;
  @override
  String toString() => messaggio;
}

/// Apre la connessione e fa l'accesso (password oppure token Microsoft).
Future<ImapClient> collega(String host, int port, String utente, String segreto, {bool oauth = false}) async {
  final client = ImapClient(isLogEnabled: false, defaultResponseTimeout: const Duration(seconds: 60));
  try {
    await client.connectToServer(host, port, isSecure: port != 143, timeout: const Duration(seconds: 30));
  } on SocketException catch (e) {
    throw Exception(e.osError?.errorCode == 7 || e.message.contains('host')
        ? 'il server «$host» non esiste: controlla il nome'
        : 'non riesco a collegarmi a «$host»: ${e.message}');
  } on HandshakeException {
    throw Exception('connessione sicura non riuscita con «$host»');
  } catch (e) {
    throw Exception('non riesco a collegarmi a «$host»');
  }
  try {
    if (oauth) {
      await client.authenticateWithOAuth2(utente, segreto);
    } else {
      await client.login(utente, segreto);
    }
  } catch (e) {
    try {
      await client.disconnect();
    } catch (_) {}
    var m = '$e'.replaceAll(RegExp(r'^.*?(NO|BAD)\s+'), '').replaceAll(RegExp(r'\[[A-Z-]+\]\s*'), '').trim();
    if (m.isEmpty || m.length > 160) m = 'credenziali non valide';
    throw AccessoNegato(m);
  }
  return client;
}

/// Cartelle da analizzare: con Gmail basta «Tutti i messaggi»; altrove tutte tranne inviata, bozze, cestino, spam.
Future<List<Mailbox>> cartelle(ImapClient client) async {
  final tutte = await client.listMailboxes(recursive: true);
  final tutti = tutte.where((m) => m.flags.contains(MailboxFlag.all)).toList();
  if (tutti.isNotEmpty) return [tutti.first];
  const salta = {MailboxFlag.sent, MailboxFlag.drafts, MailboxFlag.trash, MailboxFlag.junk, MailboxFlag.noSelect};
  return tutte.where((m) => !m.flags.any(salta.contains) && !_nomiDaSaltare.hasMatch(m.path)).toList();
}

/// Intestazioni di un'email → riga per l'archivio (o null se manca il mittente).
/// Il link di disiscrizione si tiene solo se l'email è firmata (DKIM verificato dal server di posta) dallo stesso
/// dominio del mittente: altrimenti chiunque potrebbe spedire un'email «da Zalando» con un link suo.
/// Le date nel futuro diventano 0 (sconosciuta). [ora] serve ai test.
Riga? rigaDaMessaggio(MimeMessage m, {DateTime? ora}) {
  final uid = m.uid;
  final da = m.from;
  if (uid == null || da == null || da.isEmpty) return null;
  final indirizzo = da.first.email.trim().toLowerCase();
  if (!indirizzo.contains('@')) return null;
  final oggetto = (m.decodeSubject() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  var disiscrizione = (m.decodeHeaderValue('list-unsubscribe') ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  var post = (m.getHeaderValue('list-unsubscribe-post') ?? '').toLowerCase().contains('one-click');
  final listId = m.getHeaderValue('list-id') ?? '';
  // il segnale «newsletter» vale anche senza firma; il link no
  final flags = segnali(oggetto, disiscrizione, listId);
  // vale solo il PRIMO Authentication-Results (il più in alto): l'ha scritto il tuo fornitore di posta
  final auth = (m.getHeader('authentication-results')?.firstOrNull?.value ?? '').replaceAll(RegExp(r'\s+'), ' ');
  if (disiscrizione.isNotEmpty && !dkimAllineato(auth, indirizzo)) {
    disiscrizione = '';
    post = false;
  }
  var quando = m.decodeDate();
  if (quando != null && quando.isAfter((ora ?? DateTime.now()).add(const Duration(seconds: futuroTollerato)))) {
    quando = null;
  }
  final nome = (da.first.personalName ?? '').replaceAll('"', '').trim();
  return Riga(
    uid,
    quando == null ? 0 : quando.millisecondsSinceEpoch / 1000,
    indirizzo,
    nome.length > 120 ? nome.substring(0, 120) : nome,
    registrato(indirizzo.split('@').last),
    oggetto.length > 300 ? oggetto.substring(0, 300) : oggetto,
    disiscrizione.length > 1000 ? disiscrizione.substring(0, 1000) : disiscrizione,
    post,
    flags,
  );
}

/// Analizza la casella e salva le intestazioni nuove. Ritorna quante ne ha lette.
Future<int> analizza(ImapClient client, Archivio archivio, int idCasella,
    {void Function(String testo, double frazione)? avanzamento, bool Function()? fermati}) async {
  var nuove = 0;
  final elenco = await cartelle(client);
  for (var fi = 0; fi < elenco.length; fi++) {
    if (fermati?.call() ?? false) throw const InterruptedException();
    final box = await client.examineMailbox(elenco[fi]);
    final uv = box.uidValidity ?? 0;
    var (vecchio, ultimo) = await archivio.statoCartella(idCasella, box.path);
    if (vecchio != uv) {
      await archivio.azzeraCartella(idCasella, box.path, uv);
      ultimo = 0;
    }
    if ((box.messagesExists) == 0) continue;
    final ricerca = await client.uidSearchMessages(searchCriteria: ultimo > 0 ? 'UID ${ultimo + 1}:*' : 'ALL');
    final uids = (ricerca.matchingSequence?.toList() ?? <int>[]).where((u) => u > ultimo).toList()..sort();
    for (var i = 0; i < uids.length; i += _blocco) {
      if (fermati?.call() ?? false) throw const InterruptedException();
      final pezzo = uids.sublist(i, (i + _blocco).clamp(0, uids.length));
      final risposta = await client.uidFetchMessages(
          MessageSequence.fromIds(pezzo, isUid: true), '(UID BODY.PEEK[HEADER.FIELDS ($campiIntestazioni)])');
      final righe = <Riga>[];
      for (final m in risposta.messages) {
        try {
          final r = rigaDaMessaggio(m);
          if (r != null) righe.add(r);
        } catch (_) {}
      }
      await archivio.salvaBlocco(idCasella, box.path, righe, pezzo.last);
      nuove += righe.length;
      final fatte = (i + pezzo.length);
      avanzamento?.call('${box.name}: $fatte di ${uids.length} email', (fi + fatte / uids.length) / elenco.length);
    }
  }
  return nuove;
}

class InterruptedException implements Exception {
  const InterruptedException();
}
