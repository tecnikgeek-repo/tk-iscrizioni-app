// Schermata principale: caselle, numeri, filtri ed elenco dei servizi trovati.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'aggiungi.dart';
import 'tk_pro.dart';
import 'analisi.dart';
import 'archivio.dart';
import 'classifica.dart';
import 'credenziali.dart';
import 'servizio.dart';
import 'tema.dart';

class SchermataHome extends StatefulWidget {
  const SchermataHome({super.key});

  @override
  State<SchermataHome> createState() => _SchermataHomeState();
}

class _SchermataHomeState extends State<SchermataHome> {
  final _analisi = Analisi.istanza;
  List<Casella> _caselle = [];
  List<Servizio> _servizi = [];
  int _totale = 0;
  bool _pronto = false;
  String _cat = '';
  String _filtroStato = '';
  String _cerca = '';
  int _giro = 0;

  @override
  void initState() {
    super.initState();
    _analisi.addListener(_cambio);
    _ricarica();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // primo avvio: benvenuto (software libero, cosa legge, cosa va in rete, statistiche) PRIMA di ogni chiamata in rete
      if (mounted) await benvenutoTk(context, righeExtra: righeBenvenuto);
      // controllo discreto: parla solo se c'è una versione nuova
      if (mounted) proponiAggiornamento(context, avvisaSeAggiornata: false);
      // invito al caffè: al primo avvio e poi al massimo una volta al mese, mai sopra un'altra finestra
      if (mounted) invitoCaffe(context);
    });
  }

  @override
  void dispose() {
    _analisi.removeListener(_cambio);
    super.dispose();
  }

  void _cambio() {
    if (_analisi.giri != _giro) {
      _giro = _analisi.giri;
      _ricarica();
      if (_analisi.errori.isNotEmpty && mounted) {
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Analisi con errori'),
            content: Text(_analisi.errori.join('\n\n')),
            actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Analisi completata: ${_analisi.ultimeNuove} email nuove lette.')));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _ricarica() async {
    final a = await Archivio.apri();
    final caselle = await a.caselle();
    final servizi = await a.servizi();
    final totale = await a.totaleEmail();
    servizi.sort((x, y) => (x.prima == 0 ? 9e12 : x.prima).compareTo(y.prima == 0 ? 9e12 : y.prima));
    if (mounted) {
      setState(() {
        _caselle = caselle;
        _servizi = servizi;
        _totale = totale;
        _pronto = true;
      });
    }
  }

  Future<void> _aggiungi() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const SchermataAggiungi()));
    if (ok != true) return;
    await _ricarica();
    final nuove = _caselle.where((c) => c.ultimaAnalisi == 0).toList();
    if (nuove.isNotEmpty) _analisi.avvia(nuove);
  }

  Future<void> _togli(Casella c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Togliere la casella?'),
        content: Text('${c.email}\n\nCancello dal telefono la password e le informazioni raccolte da questa casella. '
            'Le tue email non vengono toccate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Togli')),
        ],
      ),
    );
    if (ok != true) return;
    await cancellaSegreto(c.email);
    await (await Archivio.apri()).togliCasella(c.id);
    _ricarica();
  }

  List<Servizio> get _visibili => _servizi.where((s) {
        if (s.cat == 'persona' && _cat != 'persona') return false;
        if (_cat.isNotEmpty && s.cat != _cat) return false;
        if (_filtroStato == 'cancellare' && s.stato != 'cancellare') return false;
        if (_filtroStato == 'nuovo' && s.stato.isNotEmpty) return false;
        if (_cerca.isNotEmpty && !'${s.nome} ${s.dominio}'.toLowerCase().contains(_cerca)) return false;
        return true;
      }).toList();

  Future<List<(String, String)>> _righeInfo() async =>
      [('Email analizzate', '${await (await Archivio.apri()).totaleEmail()}')];

  Future<void> _esporta() async {
    final righe = _visibili;
    if (righe.isEmpty) return;
    final caselle = {for (final c in _caselle) c.id: c.email};
    // «'» davanti a = + - @: nomi e oggetti li sceglie chi spedisce le email, Excel non deve leggerli come formule
    String q(String v) => '"${cellaCsv(v).replaceAll('"', '""')}"';
    final b = StringBuffer('﻿Servizio;Dominio;Tipo;Iscritto dal;Ultima email;Email ricevute;Caselle;Stato;Nota;Disiscrizione\r\n');
    for (final s in righe) {
      final (https, mailto) = linkDisiscrizione(s.disiscrizione);
      b.write([
        q(s.nome), q(s.dominio), q(categorie[s.cat]!.$1), data(s.prima), data(s.ultima), '${s.n}',
        q(s.caselle.map((i) => caselle[i] ?? '').join(', ')), q(statiServizio[s.stato]?.$1 ?? ''), q(s.nota),
        q(https.isNotEmpty ? https : mailto),
      ].join(';'));
      b.write('\r\n');
    }
    final dir = await getTemporaryDirectory();
    final oggi = DateTime.now();
    final f = File('${dir.path}/iscrizioni-${oggi.year}-${oggi.month.toString().padLeft(2, '0')}-'
        '${oggi.day.toString().padLeft(2, '0')}.csv');
    await f.writeAsString(b.toString());
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/csv')], text: 'Le mie iscrizioni'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _caselle.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _analisi.inCorso ? _analisi.ferma : () => _analisi.avvia(_caselle),
              backgroundColor: _analisi.inCorso ? navy : accento,
              foregroundColor: Colors.white,
              icon: Icon(_analisi.inCorso ? Icons.stop : Icons.refresh),
              label: Text(_analisi.inCorso ? 'Ferma' : 'Analizza'),
            ),
      body: Column(
        children: [
          Testata(
            sottotitolo: 'A cosa sei iscritto con la tua email',
            azioni: [
              if (_servizi.isNotEmpty) AzioneTk(Icons.ios_share, 'Esporta per Excel', _esporta),
              AzioneTk(Icons.info, 'Informazioni',
                  () => apriInformazioni(context,
                      righe: _righeInfo,
                      notaDati: notaDatiInformazioni)),
            ],
          ),
          if (_analisi.inCorso)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_analisi.testo,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: grigio500, fontSize: 12.5)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                    value: _analisi.frazione <= 0 ? null : _analisi.frazione,
                    color: accento,
                    backgroundColor: grigio200,
                    borderRadius: BorderRadius.circular(4)),
              ]),
            ),
          Expanded(child: !_pronto ? const SizedBox() : (_caselle.isEmpty ? _vuota() : _elenco())),
        ],
      ),
    );
  }

  Widget _vuota() => ListView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(context).padding.bottom),
        children: [
          CardTk(
            padding: const EdgeInsets.all(22),
            child: Column(children: [
              const LogoTk(lato: 76),
              const SizedBox(height: 14),
              const Text('A cosa sei iscritto con la tua email?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                  'Collega la tua casella: tk-iscrizioni legge mittenti e oggetti delle email e ti mostra a quali siti, '
                  'servizi e newsletter sei iscritto, da quando, e come uscirne.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: grigio500, fontSize: 14, height: 1.4)),
              const SizedBox(height: 16),
              for (final (n, t, d) in [
                ('01', 'Aggiungi la casella', 'Gmail, Aruba, Libero, Virgilio, Yahoo, iCloud…'),
                ('02', 'Analizza', 'Solo le intestazioni, sul tuo telefono'),
                ('03', 'Fai pulizia', 'Disiscriviti o cancella gli account che non usi'),
              ])
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: grigio50, borderRadius: BorderRadius.circular(12), border: Border.all(color: grigio200)),
                  child: Row(children: [
                    Text(n, style: const TextStyle(color: accento, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        Text(d, style: const TextStyle(color: grigio500, fontSize: 12.5)),
                      ]),
                    ),
                  ]),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: _aggiungi, icon: const Icon(Icons.add), label: const Text('Aggiungi la tua casella')),
              const SizedBox(height: 10),
              const Text('Le email non escono dal telefono · password cifrate · gratuito',
                  textAlign: TextAlign.center, style: TextStyle(color: grigio500, fontSize: 12)),
            ]),
          ),
        ],
      );

  Widget _elenco() {
    final veri = _servizi.where((s) => s.cat != 'persona').toList();
    final visibili = _visibili;
    final caselle = {for (final c in _caselle) c.id: c.email};
    return RefreshIndicator(
      onRefresh: _ricarica,
      child: ListView(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 90 + MediaQuery.of(context).padding.bottom),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _numero('${veri.length}', 'Servizi trovati', navy),
              _numero('${veri.where((s) => s.cat == 'account' || s.cat == 'social').length}', 'Con un account', accento),
              _numero('${veri.where((s) => s.cat == 'newsletter' || s.lst > 0).length}', 'Newsletter',
                  const Color(0xFFD97706)),
              _numero('${veri.where((s) => s.stato == 'cancellare').length}', 'Da cancellare', rosso),
            ],
          ),
          const SizedBox(height: 14),
          CardTk(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LE TUE CASELLE · ${_totale.toString()} EMAIL ANALIZZATE',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: grigio500, letterSpacing: .5)),
              for (final c in _caselle)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(c.email, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    c.errore.isNotEmpty
                        ? 'Errore: ${c.errore}'
                        : (c.ultimaAnalisi > 0 ? '${c.email_} email · ${data(c.ultimaAnalisi)}' : 'Non ancora analizzata'),
                    style: TextStyle(color: c.errore.isNotEmpty ? rosso : grigio500, fontSize: 12),
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        onPressed: _analisi.inCorso ? null : () => _analisi.avvia([c]),
                        icon: const Icon(Icons.refresh, color: navy),
                        tooltip: 'Analizza questa casella'),
                    IconButton(
                        onPressed: () => _togli(c),
                        icon: const Icon(Icons.delete_outline, color: rosso),
                        tooltip: 'Togli la casella'),
                  ]),
                ),
              TextButton.icon(
                  onPressed: _aggiungi,
                  icon: const Icon(Icons.add, color: accentoScuro),
                  label: const Text('Aggiungi casella', style: TextStyle(color: accentoScuro))),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (t) => setState(() => _cerca = t.trim().toLowerCase()),
            decoration: const InputDecoration(
                hintText: 'Cerca un servizio…', prefixIcon: Icon(Icons.search), fillColor: Colors.white),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('Tutti ${veri.length}', _cat == '' && _filtroStato == '', () => setState(() {
                    _cat = '';
                    _filtroStato = '';
                  })),
              for (final k in categorie.keys)
                _chip('${categorie[k]!.$1} ${_servizi.where((s) => s.cat == k).length}', _cat == k,
                    () => setState(() => _cat = _cat == k ? '' : k)),
              _chip('Da cancellare', _filtroStato == 'cancellare',
                  () => setState(() => _filtroStato = _filtroStato == 'cancellare' ? '' : 'cancellare')),
              _chip('Da decidere', _filtroStato == 'nuovo',
                  () => setState(() => _filtroStato = _filtroStato == 'nuovo' ? '' : 'nuovo')),
            ]),
          ),
          const SizedBox(height: 10),
          if (visibili.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                  _servizi.isEmpty
                      ? (_analisi.inCorso ? 'Analisi in corso…' : 'Premi «Analizza» per leggere la casella.')
                      : 'Nessun servizio con questi filtri.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: grigio500)),
            ),
          for (final s in visibili)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardTk(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SchermataServizio(servizio: s, caselle: caselle)));
                  _ricarica();
                },
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(s.dominio, style: const TextStyle(color: grigio500, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Pilla(categorie[s.cat]!.$1, coloriCategoria[s.cat]!, piena: false),
                        if (s.stato.isNotEmpty) Pilla(statiServizio[s.stato]!.$1, statiServizio[s.stato]!.$2, piena: false),
                      ]),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('ISCRITTO DAL', style: TextStyle(color: grigio500, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    Text(data(s.prima), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${s.n} email', style: const TextStyle(color: grigio500, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _numero(String n, String etichetta, Color colore) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: colore, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(n, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
          Text(etichetta.toUpperCase(),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: grigio500)),
        ]),
      );

  Widget _chip(String t, bool scelto, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(t),
          selected: scelto,
          showCheckmark: false,
          selectedColor: navy,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: scelto ? Colors.white : navy3, fontWeight: FontWeight.w600),
          onSelected: (_) => onTap(),
        ),
      );
}
