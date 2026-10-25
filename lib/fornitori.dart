// Fornitori di posta noti: server IMAP e cosa deve fare l'utente per entrare. Nessuna ricerca su internet.

class Fornitore {
  const Fornitore(this.chiave, this.nome, this.host, this.domini, this.aiuto,
      {this.port = 993, this.oauth = false, this.linkAiuto = '', this.testoLink = '', this.etichettaPassword = ''});

  final String chiave;
  final String nome;
  final String host;
  final int port;
  final bool oauth;
  final List<String> domini;
  final String aiuto;
  final String linkAiuto;
  final String testoLink;
  final String etichettaPassword;
}

const fornitori = [
  Fornitore('gmail', 'Gmail', 'imap.gmail.com', ['gmail.com', 'googlemail.com'],
      'Gmail non accetta la password normale: serve una «password per le app» (16 lettere). Si crea in un minuto '
          'dal tuo account Google; serve la verifica in due passaggi attiva.',
      linkAiuto: 'https://myaccount.google.com/apppasswords',
      testoLink: 'Crea la password per le app',
      etichettaPassword: 'Password per le app (16 lettere)'),
  Fornitore('outlook', 'Outlook / Hotmail', 'outlook.office365.com',
      ['outlook.com', 'outlook.it', 'hotmail.com', 'hotmail.it', 'live.com', 'live.it', 'msn.com'],
      'Microsoft non accetta più la password nelle app: si entra con il pulsante «Accedi con Microsoft», dalla '
          'pagina ufficiale di Microsoft.',
      oauth: true),
  Fornitore('aruba', 'Aruba (dominio personale)', 'imaps.aruba.it', ['aruba.it'],
      'Usa la password della casella, la stessa della webmail di Aruba.'),
  Fornitore('arubapec', 'Aruba PEC', 'imaps.pec.aruba.it', ['pec.it'], 'Usa la password della casella PEC.'),
  Fornitore('libero', 'Libero', 'imapmail.libero.it', ['libero.it', 'inwind.it', 'iol.it', 'blu.it', 'giallo.it'],
      'Usa la password di Libero Mail.'),
  Fornitore('virgilio', 'Virgilio', 'in.virgilio.it', ['virgilio.it'], 'Usa la password di Virgilio Mail.'),
  Fornitore('alice', 'Alice / TIN', 'in.alice.it', ['alice.it', 'tin.it'], 'Usa la password della casella.'),
  Fornitore('tiscali', 'Tiscali', 'imap.tiscali.it', ['tiscali.it'], 'Usa la password di Tiscali Mail.'),
  Fornitore('yahoo', 'Yahoo', 'imap.mail.yahoo.com', ['yahoo.com', 'yahoo.it', 'ymail.com', 'rocketmail.com'],
      'Yahoo vuole una «password per le app», da creare nelle impostazioni di sicurezza dell\'account.',
      linkAiuto: 'https://login.yahoo.com/account/security',
      testoLink: 'Apri la sicurezza di Yahoo',
      etichettaPassword: 'Password per le app'),
  Fornitore('icloud', 'iCloud', 'imap.mail.me.com', ['icloud.com', 'me.com', 'mac.com'],
      'iCloud vuole una «password specifica per le app», da creare sul sito dell\'ID Apple.',
      linkAiuto: 'https://account.apple.com/account/manage',
      testoLink: 'Apri l\'account Apple',
      etichettaPassword: 'Password specifica per le app'),
  Fornitore('gmx', 'GMX', 'imap.gmx.com', ['gmx.com', 'gmx.it'],
      'Nelle impostazioni di GMX va attivato l\'accesso IMAP; poi usa la password della casella.'),
  Fornitore('altro', 'Altro (scrivo io il server)', '', [],
      'Se il dominio è su Aruba scegli «Aruba (dominio personale)». Altrimenti scrivi il server IMAP del tuo '
          'fornitore (di solito «imap.» o «mail.» seguito dal dominio) e la password della casella.'),
];

Fornitore fornitore(String chiave) => fornitori.firstWhere((f) => f.chiave == chiave, orElse: () => fornitori.last);

Fornitore? riconosci(String email) {
  final dom = email.trim().toLowerCase().split('@').last;
  for (final f in fornitori) {
    if (f.domini.contains(dom)) return f;
  }
  return null;
}

String hostProbabile(String email) {
  final dom = email.trim().toLowerCase().split('@').last;
  return dom.contains('.') ? 'imap.$dom' : '';
}
