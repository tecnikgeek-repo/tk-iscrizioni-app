// Archivio locale (SQLite) delle intestazioni analizzate e delle note sui servizi. Resta sul telefono.
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'classifica.dart';

class Casella {
  Casella(this.id, this.email, this.fornitore, this.host, this.port, this.auth, this.ultimaAnalisi, this.errore,
      this.email_);

  final int id;
  final String email;
  final String fornitore;
  final String host;
  final int port;
  final String auth;
  final double ultimaAnalisi;
  final String errore;
  final int email_; // quante email analizzate
}

class Servizio {
  Servizio({
    required this.dominio,
    required this.nome,
    required this.n,
    required this.prima,
    required this.ultima,
    required this.acc,
    required this.sic,
    required this.acq,
    required this.lst,
    required this.caselle,
    required this.cat,
    required this.disiscrizione,
    required this.unClic,
    required this.stato,
    required this.nota,
  });

  final String dominio, nome, cat, disiscrizione, stato, nota;
  final int n, acc, sic, acq, lst;
  final double prima, ultima;
  final List<int> caselle;
  final bool unClic;
}

class Riga {
  Riga(this.uid, this.ts, this.mittente, this.nome, this.dominio, this.oggetto, this.disiscrizione, this.unClic,
      this.segnali);

  final int uid;
  final double ts;
  final String mittente, nome, dominio, oggetto, disiscrizione;
  final bool unClic;
  final int segnali;
}

const versioneArchivio = 2;

class Archivio {
  Archivio._(this.db);

  final Database db;
  static Archivio? _istanza;

  static Future<Archivio> apri() async {
    if (_istanza != null) return _istanza!;
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'archivio.db'),
      version: versioneArchivio,
      // 2 (versione 1.2.0): i link di disiscrizione valgono solo con DKIM verificato. Quelli salvati prima non erano
      // controllati: si tolgono e la prossima analisi rilegge le intestazioni (anche l'esito DKIM).
      onUpgrade: (db, vecchia, _) async {
        if (vecchia < 2) {
          await db.execute("UPDATE messages SET unsub='', unsub_post=0");
          await db.execute('UPDATE folders SET last_uid=0');
        }
      },
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE accounts (id INTEGER PRIMARY KEY, email TEXT UNIQUE NOT NULL, provider TEXT, '
            "host TEXT, port INTEGER DEFAULT 993, auth TEXT DEFAULT 'password', last_scan REAL DEFAULT 0, "
            "last_error TEXT DEFAULT '')");
        await db.execute('CREATE TABLE folders (account_id INTEGER, name TEXT, uidvalidity INTEGER, '
            'last_uid INTEGER DEFAULT 0, PRIMARY KEY (account_id, name))');
        await db.execute('CREATE TABLE messages (account_id INTEGER, folder TEXT, uid INTEGER, ts REAL, '
            'from_addr TEXT, from_name TEXT, domain TEXT, subject TEXT, unsub TEXT, unsub_post INTEGER, '
            'flags INTEGER, PRIMARY KEY (account_id, folder, uid))');
        await db.execute('CREATE INDEX messages_domain ON messages(domain)');
        await db.execute("CREATE TABLE services (domain TEXT PRIMARY KEY, status TEXT DEFAULT '', note TEXT DEFAULT '')");
      },
    );
    return _istanza = Archivio._(db);
  }

  // ---- caselle
  Future<List<Casella>> caselle() async {
    final r = await db.rawQuery(
        'SELECT a.*, (SELECT COUNT(*) FROM messages m WHERE m.account_id=a.id) n FROM accounts a ORDER BY a.id');
    return [
      for (final x in r)
        Casella(x['id'] as int, x['email'] as String, '${x['provider']}', '${x['host']}', x['port'] as int,
            '${x['auth']}', (x['last_scan'] as num).toDouble(), '${x['last_error'] ?? ''}', x['n'] as int)
    ];
  }

  Future<void> aggiungiCasella(String email, String fornitore, String host, int port, String auth) =>
      db.rawInsert(
          'INSERT INTO accounts(email,provider,host,port,auth) VALUES(?,?,?,?,?) ON CONFLICT(email) DO UPDATE SET '
          'provider=excluded.provider, host=excluded.host, port=excluded.port, auth=excluded.auth',
          [email, fornitore, host, port, auth]);

  Future<void> togliCasella(int id) => db.transaction((t) async {
        await t.delete('messages', where: 'account_id=?', whereArgs: [id]);
        await t.delete('folders', where: 'account_id=?', whereArgs: [id]);
        await t.delete('accounts', where: 'id=?', whereArgs: [id]);
      });

  Future<void> segnaAnalisi(int id, double ts, String errore) =>
      db.update('accounts', {'last_scan': ts, 'last_error': errore}, where: 'id=?', whereArgs: [id]);

  // ---- cartelle e messaggi
  Future<(int?, int)> statoCartella(int id, String nome) async {
    final r = await db.query('folders', where: 'account_id=? AND name=?', whereArgs: [id, nome]);
    if (r.isEmpty) return (null, 0);
    return (r.first['uidvalidity'] as int?, r.first['last_uid'] as int);
  }

  Future<void> azzeraCartella(int id, String nome, int uidvalidity) => db.transaction((t) async {
        await t.delete('messages', where: 'account_id=? AND folder=?', whereArgs: [id, nome]);
        await t.insert('folders', {'account_id': id, 'name': nome, 'uidvalidity': uidvalidity, 'last_uid': 0},
            conflictAlgorithm: ConflictAlgorithm.replace);
      });

  Future<void> salvaBlocco(int id, String cartella, List<Riga> righe, int ultimoUid) => db.transaction((t) async {
        final b = t.batch();
        for (final r in righe) {
          b.insert(
              'messages',
              {
                'account_id': id, 'folder': cartella, 'uid': r.uid, 'ts': r.ts, 'from_addr': r.mittente,
                'from_name': r.nome, 'domain': r.dominio, 'subject': r.oggetto, 'unsub': r.disiscrizione,
                'unsub_post': r.unClic ? 1 : 0, 'flags': r.segnali,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        b.rawUpdate('UPDATE folders SET last_uid=MAX(last_uid,?) WHERE account_id=? AND name=?',
            [ultimoUid, id, cartella]);
        await b.commit(noResult: true);
      });

  Future<int> totaleEmail() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM messages')) ?? 0;

  // ---- servizi
  Future<List<Servizio>> servizi() async {
    final mie = (await caselle()).map((c) => c.email.split('@').last).toSet()..removeAll(freemail);
    // oltre questa data un'email è «dal futuro» (data falsa): non conta per l'ultima email né per il link
    final limite = DateTime.now().millisecondsSinceEpoch / 1000 + futuroTollerato;
    final righe = await db.rawQuery(
        'SELECT domain, COUNT(*) n, MIN(CASE WHEN ts>0 AND ts<=? THEN ts END) first, '
        'MAX(CASE WHEN ts<=? THEN ts ELSE 0 END) last, '
        'SUM((flags&1)>0) acc, SUM((flags&2)>0) sec, SUM((flags&4)>0) pur, SUM((flags&8)>0) lst, '
        "GROUP_CONCAT(DISTINCT account_id) accs FROM messages WHERE domain<>'' GROUP BY domain",
        [limite, limite]);
    final nomi = <String, List<(String, int)>>{};
    for (final r in await db.rawQuery("SELECT domain, from_name, COUNT(*) c FROM messages WHERE from_name<>'' "
        'GROUP BY domain, from_name ORDER BY c DESC')) {
      nomi.putIfAbsent('${r['domain']}', () => []).add(('${r['from_name']}', r['c'] as int));
    }
    // il link dell'email più recente (con DKIM verificato: gli altri non vengono salvati), mai da date future
    final disc = <String, (String, bool)>{};
    for (final r in await db.rawQuery(
        "SELECT domain, unsub, unsub_post, MAX(ts) FROM messages WHERE unsub<>'' AND ts<=? GROUP BY domain",
        [limite])) {
      disc['${r['domain']}'] = ('${r['unsub']}', (r['unsub_post'] as int) == 1);
    }
    final note = <String, (String, String)>{};
    for (final r in await db.query('services')) {
      note['${r['domain']}'] = ('${r['status']}', '${r['note']}');
    }
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    return [
      for (final r in righe)
        Servizio(
          dominio: '${r['domain']}',
          nome: nomeServizio(nomi['${r['domain']}'] ?? [], '${r['domain']}'),
          n: i(r['n']),
          prima: (r['first'] as num?)?.toDouble() ?? 0,
          ultima: (r['last'] as num?)?.toDouble() ?? 0,
          acc: i(r['acc']),
          sic: i(r['sec']),
          acq: i(r['pur']),
          lst: i(r['lst']),
          caselle: '${r['accs'] ?? ''}'.split(',').where((x) => x.isNotEmpty).map(int.parse).toList(),
          cat: categoria('${r['domain']}', i(r['acc']), i(r['sec']), i(r['pur']), i(r['lst']), mie),
          disiscrizione: disc['${r['domain']}']?.$1 ?? '',
          unClic: disc['${r['domain']}']?.$2 ?? false,
          stato: note['${r['domain']}']?.$1 ?? '',
          nota: note['${r['domain']}']?.$2 ?? '',
        )
    ];
  }

  Future<List<Map<String, Object?>>> recenti(String dominio) => db.rawQuery(
      'SELECT m.ts, m.subject, m.from_addr FROM messages m WHERE m.domain=? ORDER BY m.ts DESC LIMIT 15', [dominio]);

  Future<void> impostaStato(String dominio, {String? stato, String? nota}) async {
    final r = await db.query('services', where: 'domain=?', whereArgs: [dominio]);
    final s = r.isEmpty ? '' : '${r.first['status']}';
    final n = r.isEmpty ? '' : '${r.first['note']}';
    await db.insert('services', {'domain': dominio, 'status': stato ?? s, 'note': nota ?? n},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
