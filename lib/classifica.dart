// Dalle intestazioni di un'email ai segnali sul servizio che l'ha mandata (stessa logica del programma per computer).

const fAccount = 1; // benvenuto, conferma iscrizione, verifica indirizzo
const fSicurezza = 2; // password, codici, nuovi accessi: c'è un account
const fAcquisti = 4; // ordini, ricevute, fatture, spedizioni
const fLista = 8; // newsletter (List-Unsubscribe / List-Id)

const _suffissi2 = {
  'co.uk', 'org.uk', 'ac.uk', 'gov.uk', 'me.uk', 'com.au', 'net.au', 'org.au', 'co.nz', 'co.za', 'co.jp', 'ne.jp',
  'co.kr', 'com.br', 'com.mx', 'com.ar', 'com.tr', 'co.in', 'com.cn', 'com.hk', 'com.sg', 'com.tw', 'co.il',
  'com.co', 'com.pe', 'com.pl', 'com.ua', 'co.id', 'com.my', 'com.ph', 'com.vn', 'co.th',
};

const _alias = {
  'facebookmail.com': 'facebook.com',
  'twitter.com': 'x.com',
  'amazonses.com': '',
  'accountprotection.microsoft.com': 'microsoft.com',
};

const freemail = {
  'gmail.com', 'googlemail.com', 'libero.it', 'inwind.it', 'iol.it', 'blu.it', 'virgilio.it', 'alice.it', 'tin.it',
  'tim.it', 'tiscali.it', 'fastwebnet.it', 'hotmail.com', 'hotmail.it', 'outlook.com', 'outlook.it', 'live.com',
  'live.it', 'msn.com', 'yahoo.com', 'yahoo.it', 'ymail.com', 'icloud.com', 'me.com', 'mac.com', 'gmx.com',
  'gmx.it', 'gmx.net', 'gmx.de', 'pec.it', 'legalmail.it', 'aruba.it', 'email.it', 'proton.me', 'protonmail.com',
  'web.de', 'aol.com', 'mail.com', 'zoho.com', 'yandex.com', 'yandex.ru', 'mail.ru',
};

const social = {
  'facebook.com', 'instagram.com', 'x.com', 'tiktok.com', 'linkedin.com', 'pinterest.com', 'reddit.com',
  'snapchat.com', 'threads.net', 'tumblr.com', 'youtube.com', 'twitch.tv', 'discord.com', 'telegram.org',
  'whatsapp.com', 'quora.com', 'medium.com', 'vk.com', 'badoo.com', 'tinder.com', 'meetup.com',
};

const categorie = {
  'account': ('Account', 'Ti sei registrato: c\'è un account con la tua email'),
  'social': ('Social', 'Social network e community'),
  'acquisti': ('Acquisti', 'Ordini, ricevute, abbonamenti'),
  'newsletter': ('Newsletter', 'Ti mandano comunicazioni o pubblicità'),
  'altro': ('Altro', 'Ti hanno scritto, senza segni chiari di iscrizione'),
  'persona': ('Persone', 'Caselle email di persone e del tuo dominio'),
};

String _norm(String s) {
  const da = 'àáâäèéêëìíîïòóôöùúûüç';
  const a = 'aaaaeeeeiiiioooouuuuc';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = da.indexOf(c);
    b.write(i >= 0 ? a[i] : c);
  }
  return b.toString();
}

final _rxAccount = RegExp(
    r'benvenut|welcome|bienvenu|bienvenid|willkommen'
    r'|conferm\w*\s+(?:la\s+tua\s+|il\s+tuo\s+|l.)?(?:e-?mail|indirizzo|account|iscrizione|registrazione)'
    r'|verific\w*\s+(?:la\s+tua\s+|il\s+tuo\s+|l.)?(?:e-?mail|indirizzo|account)'
    r'|verify\s+(?:your\s+)?(?:e-?mail|address|account)'
    r'|confirm\s+(?:your\s+)?(?:e-?mail|address|account|registration|sign.?up)'
    r'|attiva\s+(?:il\s+tuo\s+|l.)?account|activate\s+(?:your\s+)?account'
    r'|registrazione\s+(?:completata|confermata|avvenuta|riuscita)|iscrizione\s+(?:completata|confermata|avvenuta)'
    r'|account\s+(?:creato|attivato|created|activated|is\s+ready|e\s+pronto)'
    r'|thanks?\s+(?:you\s+)?for\s+(?:signing\s+up|registering|joining|creating)'
    r'|grazie\s+per\s+(?:esserti|la\s+tua|averci)\s+\w*\s*(?:iscritt|registra)'
    r'|grazie\s+per\s+(?:l.)?iscrizione|sei\s+iscritt|ti\s+sei\s+iscritt|ti\s+sei\s+registrat'
    r'|you.?re\s+(?:now\s+)?(?:registered|signed\s+up|in\b)|complete\s+your\s+(?:registration|sign.?up|profile)'
    r'|completa\s+(?:la\s+tua\s+)?(?:registrazione|iscrizione)|crea(?:zione)?\s+(?:del\s+)?(?:tuo\s+)?account');
final _rxSicurezza = RegExp(
    r'password|passcode|codice\s+(?:di\s+)?(?:verifica|sicurezza|accesso|conferma|login)|verification\s+code'
    r'|security\s+code|one.?time|\botp\b|nuovo\s+accesso|new\s+(?:sign.?in|login|device)|nuovo\s+dispositivo'
    r'|accesso\s+(?:al\s+tuo\s+account|da\s+un\s+nuovo|effettuato)|sign.?in\s+(?:attempt|alert|code)'
    r'|security\s+alert|avviso\s+di\s+sicurezza|avviso\s+sicurezza|autenticazione\s+a\s+due|two.?factor|\b2fa\b'
    r'|login\s+code|reimposta|reset\s+your|recupero\s+(?:account|password)|codice\s+\d{4,}|\b\d{6}\b.*codice'
    r'|is\s+your\s+\w+\s+code|e\s+il\s+tuo\s+codice');
final _rxAcquisti = RegExp(
    r'\bordine\b|\border\b|ricevuta|receipt|fattura|invoice|spedit|spedizione|shipped|shipping|consegn|deliver'
    r'|pagamento|payment|abbonament|subscription|rinnov|renewal|acquisto|purchase|prenotazione|booking'
    r'|biglietto|\bticket|reso\b|rimborso|refund|transazione|transaction|addebito');

String _pulisci(String host) {
  host = host.trim().toLowerCase();
  while (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  return host;
}

/// Dominio «registrato» (news.mail.amazon.co.uk → amazon.co.uk), senza gli alias dei servizi.
String organizzativo(String host) {
  host = _pulisci(host);
  final parti = host.split('.');
  if (parti.length <= 2) return host;
  final n = _suffissi2.contains(parti.sublist(parti.length - 2).join('.')) ? 3 : 2;
  return parti.sublist(parti.length - n).join('.');
}

String registrato(String host) {
  host = _pulisci(host);
  if (_alias.containsKey(host)) return _alias[host]!;
  final reg = organizzativo(host);
  return _alias[reg] ?? reg;
}

// ---- Authentication-Results (RFC 8601): l'intestazione che il server di posta aggiunge dopo aver verificato la
// firma DKIM del mittente. Vale solo la PRIMA (la più in alto): l'ha scritta il tuo fornitore; quelle più in basso
// possono arrivare già scritte da chi ha spedito l'email.
final _rxDkimPass = RegExp(r'^\s*dkim\s*=\s*pass\b', caseSensitive: false);
final _rxHeaderD = RegExp(r'\bheader\.d\s*=\s*"?([a-z0-9.-]+)', caseSensitive: false);
final _rxHeaderI = RegExp(r'\bheader\.i\s*=\s*"?[^@\s;"]*@([a-z0-9.-]+)', caseSensitive: false);

String _senzaCommenti(String testo) {
  String? prima;
  while (prima != testo) {
    prima = testo;
    testo = testo.replaceAll(RegExp(r'\([^()]*\)'), ' ');
  }
  return testo;
}

/// Authentication-Results → domini delle firme DKIM verificate (dkim=pass).
List<String> dkimDomini(String authResults) {
  final out = <String>[];
  for (final pezzo in _senzaCommenti(authResults).split(';')) {
    if (!_rxDkimPass.hasMatch(pezzo)) continue;
    final m = _rxHeaderD.firstMatch(pezzo) ?? _rxHeaderI.firstMatch(pezzo);
    if (m != null) out.add(_pulisci(m.group(1)!));
  }
  return out;
}

/// Vero se il server di posta ha verificato una firma DKIM dello stesso dominio del mittente (allineamento
/// «relaxed» come in DMARC: news.zalando.it e zalando.it vanno bene insieme).
bool dkimAllineato(String authResults, String mittente) {
  final org = organizzativo(mittente.split('@').last);
  return org.contains('.') && dkimDomini(authResults).any((d) => organizzativo(d) == org);
}

/// Date più avanti di un giorno (fusi orari a parte) sono false: si ignorano (secondi).
const futuroTollerato = 86400;

/// Vero se l'host del link appartiene al dominio del servizio (anche tramite gli alias, es. facebookmail.com).
bool stessoServizio(String host, String dominio) {
  host = _pulisci(host);
  return host.isNotEmpty &&
      dominio.isNotEmpty &&
      (organizzativo(host) == organizzativo(dominio) || registrato(host) == dominio);
}

int segnali(String oggetto, String disiscrizione, String listId) {
  final s = _norm(oggetto);
  var f = 0;
  if (_rxAccount.hasMatch(s)) f |= fAccount;
  if (_rxSicurezza.hasMatch(s)) f |= fSicurezza;
  if (_rxAcquisti.hasMatch(s)) f |= fAcquisti;
  if (disiscrizione.isNotEmpty || listId.isNotEmpty) f |= fLista;
  return f;
}

String categoria(String dominio, int acc, int sic, int acq, int lst, Set<String> mieiDomini) {
  if (freemail.contains(dominio) || mieiDomini.contains(dominio)) return 'persona';
  if (social.contains(dominio)) return 'social';
  if (acc > 0 || sic > 0) return 'account';
  if (acq > 0) return 'acquisti';
  if (lst > 0) return 'newsletter';
  return 'altro';
}

final _cattivo =
    RegExp(r'^(no.?reply|do.?not.?reply|notifications?|notifiche|newsletter|info|support|team|mailer)$', caseSensitive: false);
final _coda = RegExp(r'\s*[|\-–·:]\s*(no.?reply|notifiche|notifications?|newsletter|team|support)\b.*$', caseSensitive: false);

/// Nome leggibile: il nome mittente più usato, ripulito; altrimenti il dominio con la maiuscola.
String nomeServizio(List<(String, int)> nomi, String dominio) {
  for (final (n0, _) in nomi) {
    final n = n0.trim();
    if (n.isEmpty || n.contains('@') || n.length > 40) continue;
    final pulito = n.replaceAll(_coda, '').trim();
    if (pulito.isNotEmpty && !_cattivo.hasMatch(pulito)) return pulito;
  }
  final base = dominio.isEmpty ? '?' : dominio.split('.').first;
  return base[0].toUpperCase() + base.substring(1);
}

/// List-Unsubscribe → (https, mailto).
(String, String) linkDisiscrizione(String intestazione) {
  var https = '', mailto = '';
  for (final m in RegExp(r'<([^>]+)>').allMatches(intestazione)) {
    final p = m.group(1)!.trim();
    if (p.toLowerCase().startsWith('https://') && https.isEmpty) https = p;
    if (p.toLowerCase().startsWith('mailto:') && mailto.isEmpty) mailto = p;
  }
  return (https, mailto);
}

/// Host del link https (o del dominio dell'indirizzo mailto) da mostrare prima di aprirlo.
String hostDi(String link) {
  if (link.toLowerCase().startsWith('mailto:')) {
    final a = link.substring(7).split('?').first;
    return a.substring(a.lastIndexOf('@') + 1).trim().toLowerCase();
  }
  return (Uri.tryParse(link)?.host ?? '').toLowerCase();
}

/// Testo per una cella del CSV: con «'» davanti se Excel lo leggerebbe come formula (nomi e oggetti arrivano
/// dalle email, li sceglie chi le spedisce).
String cellaCsv(String valore) =>
    valore.isNotEmpty && '=+-@\t\r'.contains(valore[0]) ? "'$valore" : valore;
