// Prova della lettura IMAP contro il finto server del programma per computer (tests/fake_imap.py).
// Uso: avviare il server (python tests/serve_fake.py <porta>) e poi: flutter test --dart-define=PORTA=<porta>
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkiscrizioni/archivio.dart' show Riga;
import 'package:tkiscrizioni/classifica.dart';
import 'package:tkiscrizioni/posta.dart';

const porta = int.fromEnvironment('PORTA');

void main() {
  test('classificazione come sul computer', () {
    expect(segnali('Il tuo codice di verifica: 482913', '', '') & fSicurezza, isNonZero);
    expect(segnali('Welcome to Canva', '', '') & fAccount, isNonZero);
    expect(segnali('Ricevuta del tuo pagamento', '', '') & fAcquisti, isNonZero);
    expect(segnali('Novità', '<https://x>', '') & fLista, isNonZero);
    expect(registrato('news.mail.amazon.co.uk'), 'amazon.co.uk');
    expect(registrato('security.facebookmail.com'), 'facebook.com');
    expect(categoria('gmail.com', 0, 0, 0, 0, {}), 'persona');
    expect(categoria('netflix.com', 1, 1, 0, 0, {}), 'account');
    expect(nomeServizio([('noreply', 3), ('Netflix', 2)], 'netflix.com'), 'Netflix');
    expect(linkDisiscrizione('<https://a/u>, <mailto:u@a>'), ('https://a/u', 'mailto:u@a'));
  });

  test('lettura IMAP dal finto server', () async {
    if (porta == 0) {
      markTestSkipped('finto server non avviato');
      return;
    }
    final c = ImapClient(isLogEnabled: false);
    await c.connectToServer('127.0.0.1', porta, isSecure: false);
    await expectLater(c.login('pietro@esempio-ditta.it', 'sbagliata'), throwsA(anything));
    await c.login('pietro@esempio-ditta.it', 'segreta');
    final elenco = await cartelle(c);
    expect(elenco.map((m) => m.path).toList(), ['INBOX', 'Lavoro è archivio']);
    final righe = <Riga>[];
    for (final m in elenco) {
      await c.examineMailbox(m);
      final r = await c.uidSearchMessages(searchCriteria: 'ALL');
      final uids = r.matchingSequence!.toList();
      final f = await c.uidFetchMessages(MessageSequence.fromIds(uids, isUid: true),
          '(UID BODY.PEEK[HEADER.FIELDS ($campiIntestazioni)])');
      righe.addAll(f.messages.map(rigaDaMessaggio).whereType<Riga>());
    }
    expect(righe.length, 15);
    final per = {for (final r in righe) r.uid: r};
    expect(per[1]!.dominio, 'netflix.com');
    expect(per[1]!.nome, 'Netflix');
    expect(per[1]!.segnali & fAccount, isNonZero);
    expect(per[5]!.oggetto, 'Saldi fino al 70% 🔥');
    expect(per[5]!.unClic, isTrue);
    expect(linkDisiscrizione(per[5]!.disiscrizione).$1, startsWith('https://zalando'));
    expect(per[7]!.dominio, 'facebook.com');
    // 13: email falsa «da Zalando» (il primo Authentication-Results dice dkim=fail), 14: firma non allineata
    expect(per[13]!.disiscrizione, isEmpty);
    expect(per[14]!.disiscrizione, isEmpty);
    // 15: data nel futuro = sconosciuta
    expect(per[15]!.ts, 0);
    expect(per[1]!.ts, closeTo(1580720400, 2));
    await c.logout();
  });
}
