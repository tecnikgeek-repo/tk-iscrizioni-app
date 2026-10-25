// Prove delle protezioni della disiscrizione e dell'esportazione (le stesse del programma per computer, test_core.py):
// link solo da email firmate DKIM dal mittente, date future ignorate, host mostrato, POST solo https verso siti
// pubblici (anche nei redirect), celle del CSV che non diventano formule.
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tkiscrizioni/classifica.dart';
import 'package:tkiscrizioni/disiscrizione.dart';
import 'package:tkiscrizioni/posta.dart';
import 'package:tkiscrizioni/servizio.dart';

const _arOutlook = 'spf=pass (sender IP is 1.2.3.4) smtp.mailfrom=shop.it; dkim=pass (signature was verified) '
    'header.d=shop.it;dmarc=pass action=none header.from=shop.it';

MimeMessage _email(String intestazioni, {int uid = 1}) {
  final m = MimeMessage.parseFromText('From: "Shop" <news@mail.shop.it>\r\nSubject: Offerte\r\n'
      'Date: Fri, 01 Jul 2022 08:00:00 +0200\r\n$intestazioni\r\n');
  m.uid = uid;
  return m;
}

const _lu = 'List-Unsubscribe: <https://shop.it/u>\r\nList-Unsubscribe-Post: List-Unsubscribe=One-Click\r\n';

Future<bool> _tutti(String host) async => true;

void main() {
  group('DKIM', () {
    test('formati di Outlook e di Gmail', () {
      expect(dkimDomini(_arOutlook), ['shop.it']);
      expect(dkimDomini('mx.google.com; dkim=pass header.i=@news.shop.it header.s=a; dkim=fail header.d=x.it'),
          ['news.shop.it']);
      expect(dkimDomini('mx.x; dkim=pass (header.d=shop.it nel commento)'), isEmpty);
    });

    test('allineamento al mittente', () {
      expect(dkimAllineato(_arOutlook, 'news@mail.shop.it'), isTrue);
      expect(dkimAllineato(_arOutlook, 'news@shop.it.truffa.com'), isFalse);
      expect(dkimAllineato('mx.x; dkim=pass header.d=co.uk', 'a@shop.co.uk'), isFalse);
      expect(dkimAllineato('', 'a@shop.it'), isFalse);
    });

    test('senza firma il link non si tiene (il segnale newsletter sì)', () {
      final r = rigaDaMessaggio(_email(_lu))!;
      expect(r.disiscrizione, '');
      expect(r.unClic, isFalse);
      expect(r.segnali & fLista, isNonZero);
    });

    test('con la firma del mittente il link resta', () {
      final r = rigaDaMessaggio(_email('Authentication-Results: mx.x; dkim=pass header.d=shop.it\r\n$_lu'))!;
      expect(linkDisiscrizione(r.disiscrizione).$1, 'https://shop.it/u');
      expect(r.unClic, isTrue);
    });

    test('vale solo il primo Authentication-Results (quello del tuo fornitore)', () {
      final r = rigaDaMessaggio(_email('Authentication-Results: mx.x; dkim=fail header.d=shop.it\r\n'
          'Authentication-Results: mx.x; dkim=pass header.d=shop.it\r\n$_lu'))!;
      expect(r.disiscrizione, '');
    });

    test('firma di un altro dominio: niente link', () {
      final r = rigaDaMessaggio(_email('Authentication-Results: mx.x; dkim=pass header.d=spedizioni.example\r\n$_lu'))!;
      expect(r.disiscrizione, '');
    });

    test('il campo è chiesto al server', () {
      expect(campiIntestazioni, contains('AUTHENTICATION-RESULTS'));
    });
  });

  test('data nel futuro: sconosciuta', () {
    final ora = DateTime.utc(2022, 7, 1, 12);
    final futura = MimeMessage.parseFromText(
        'From: a@shop.it\r\nSubject: x\r\nDate: Fri, 01 Jan 2099 08:00:00 +0100\r\n\r\n')
      ..uid = 2;
    expect(rigaDaMessaggio(futura, ora: ora)!.ts, 0);
    expect(rigaDaMessaggio(_email(''), ora: ora)!.ts, closeTo(1656655200, 2));
  });

  group('host del link', () {
    test('https e mailto', () {
      expect(hostDi('https://Liste.Shop.it/u?x=1'), 'liste.shop.it');
      expect(hostDi('mailto:unsub@liste.shop.it?subject=x'), 'liste.shop.it');
    });

    test('stesso servizio o no', () {
      expect(stessoServizio('liste.shop.it', 'shop.it'), isTrue);
      expect(stessoServizio('security.facebookmail.com', 'facebook.com'), isTrue);
      expect(stessoServizio('shop.it.truffa.com', 'shop.it'), isFalse);
      expect(avvisoLink('https://liste.shop.it/u', 'shop.it'), isNot(contains('Attenzione')));
      final a = avvisoLink('https://mailer.esempio.com/u', 'shop.it');
      expect(a, contains('«mailer.esempio.com»'));
      expect(a, contains('Attenzione'));
    });
  });

  group('indirizzi', () {
    test('pubblici sì, locali no', () {
      bool p(String s) => indirizzoPubblico(InternetAddress(s));
      expect(p('93.184.216.34'), isTrue);
      expect(p('2a00:1450:4002:400::200e'), isTrue);
      for (final s in [
        '127.0.0.1', '10.1.2.3', '172.16.0.1', '172.31.255.255', '192.168.1.1', '169.254.1.1', '100.64.0.1', '0.0.0.0',
        '224.0.0.1', '255.255.255.255', '::1', '::', 'fe80::1', 'fd00::1', 'ff02::1', '::ffff:192.168.1.1',
      ]) {
        expect(p(s), isFalse, reason: s);
      }
      expect(p('::ffff:8.8.8.8'), isTrue);
    });

    test('solo https verso host ammessi', () async {
      expect(await urlAmmesso('https://shop.it/u', consenti: _tutti), isTrue);
      expect(await urlAmmesso('http://shop.it/u', consenti: _tutti), isFalse);
      expect(await urlAmmesso('https://127.0.0.1/u'), isFalse);
      expect(await urlAmmesso('https://192.168.1.1/u'), isFalse);
      expect(await urlAmmesso('https://[::1]/u'), isFalse);
      expect(await urlAmmesso('ftp://shop.it/u', consenti: _tutti), isFalse);
    });
  });

  group('POST di disiscrizione', () {
    test('manda One-Click e non segue i redirect da solo', () async {
      final viste = <http.BaseRequest>[];
      final c = MockClient((r) async {
        viste.add(r);
        return http.Response('', 200);
      });
      expect(await inviaDisiscrizione('https://shop.it/u', client: c, consenti: _tutti), 200);
      final r = viste.single as http.Request;
      expect(r.method, 'POST');
      expect(r.body, 'List-Unsubscribe=One-Click');
      expect(r.followRedirects, isFalse);
    });

    test('redirect verso un sito ammesso: seguito', () async {
      final c = MockClient((r) async => r.url.host == 'shop.it'
          ? http.Response('', 302, headers: {'location': 'https://liste.shop.it/fatto'})
          : http.Response('', 200));
      expect(await inviaDisiscrizione('https://shop.it/u', client: c, consenti: _tutti), 200);
    });

    test('redirect verso http o la rete locale: rifiutato', () async {
      Future<bool> soloShop(String h) async => h.endsWith('shop.it');
      for (final verso in ['http://shop.it/x', 'https://192.168.1.1/admin', 'https://router.lan/']) {
        final c = MockClient((r) async => r.url.host == 'shop.it'
            ? http.Response('', 302, headers: {'location': verso})
            : http.Response('', 200));
        await expectLater(inviaDisiscrizione('https://shop.it/u', client: c, consenti: soloShop),
            throwsA(isA<LinkNonAmmesso>()), reason: verso);
      }
    });

    test('link non https: niente richiesta', () async {
      var chiamate = 0;
      final c = MockClient((r) async {
        chiamate++;
        return http.Response('', 200);
      });
      await expectLater(
          inviaDisiscrizione('http://shop.it/u', client: c, consenti: _tutti), throwsA(isA<LinkNonAmmesso>()));
      expect(chiamate, 0);
    });

    test('troppi redirect: fermo', () async {
      final c = MockClient((r) async => http.Response('', 302, headers: {'location': 'https://shop.it/ancora'}));
      await expectLater(
          inviaDisiscrizione('https://shop.it/u', client: c, consenti: _tutti), throwsA(isA<LinkNonAmmesso>()));
    });
  });

  test('CSV: niente formule dalle email', () {
    expect(cellaCsv('=HYPERLINK("x")'), "'=HYPERLINK(\"x\")");
    expect(cellaCsv('+39 123'), "'+39 123");
    expect(cellaCsv('-2'), "'-2");
    expect(cellaCsv('@SOMMA(A1)'), "'@SOMMA(A1)");
    expect(cellaCsv('\tx'), "'\tx");
    expect(cellaCsv('Zalando'), 'Zalando');
    expect(cellaCsv(''), '');
  });

  test('stato dopo la disiscrizione: «Richiesta inviata»', () {
    expect(statiServizio['disiscritto']!.$1, 'Richiesta inviata');
  });
}
