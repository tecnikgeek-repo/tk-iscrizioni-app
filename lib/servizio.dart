// Dettaglio di un servizio: date, segnali, disiscrizione, come cancellare l'account, stato e nota.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'archivio.dart';
import 'classifica.dart';
import 'disiscrizione.dart';
import 'tema.dart';

const statiServizio = {
  '': ('', grigio500),
  'tenere': ('Da tenere', verde),
  'cancellare': ('Da cancellare', rosso),
  'fatto': ('Account cancellato', grigio500),
  // la richiesta è partita: se il mittente la rispetta lo dice solo il tempo
  'disiscritto': ('Richiesta inviata', grigio500),
};

/// Dove porta il link, e un avviso se non è il dominio del servizio (come _avviso_link del programma per computer).
String avvisoLink(String link, String dominio) {
  final host = hostDi(link);
  final dove = link.toLowerCase().startsWith('mailto:') ? "L'email va a un indirizzo di" : 'Il link porta a';
  var testo = '$dove «${host.isEmpty ? '?' : host}».';
  if (!stessoServizio(host, dominio)) {
    testo += '\nAttenzione: non è il dominio del servizio ($dominio). Spesso è la ditta che spedisce le sue '
        'newsletter, ma se non ti convince annulla.';
  }
  return testo;
}

class SchermataServizio extends StatefulWidget {
  const SchermataServizio({super.key, required this.servizio, required this.caselle});

  final Servizio servizio;
  final Map<int, String> caselle;

  @override
  State<SchermataServizio> createState() => _SchermataServizioState();
}

class _SchermataServizioState extends State<SchermataServizio> {
  late String _stato = widget.servizio.stato;
  late final _nota = TextEditingController(text: widget.servizio.nota);
  List<Map<String, Object?>> _ultime = [];
  bool _occupato = false;

  @override
  void initState() {
    super.initState();
    Archivio.apri().then((a) => a.recenti(widget.servizio.dominio)).then((r) {
      if (mounted) setState(() => _ultime = r);
    }).catchError((_) {});
  }

  Future<void> _salvaStato(String s) async {
    final nuovo = _stato == s ? '' : s;
    await (await Archivio.apri()).impostaStato(widget.servizio.dominio, stato: nuovo);
    setState(() => _stato = nuovo);
  }

  Future<void> _salvaNota() async =>
      (await Archivio.apri()).impostaStato(widget.servizio.dominio, nota: _nota.text.trim());

  void _messaggio(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  /// Conferma con l'host del link in vista (e l'avviso se non è il dominio del servizio).
  Future<bool> _chiedi(String titolo, String testo, String link, String pulsante) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(titolo),
          content: SingleChildScrollView(
            child: Text('$testo\n\n${avvisoLink(link, widget.servizio.dominio)}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(pulsante)),
          ],
        ),
      ) ==
      true;

  Future<void> _disiscriviti() async {
    final s = widget.servizio;
    final (https, mailto) = linkDisiscrizione(s.disiscrizione);
    final titolo = 'Disiscriverti da ${s.nome}?';
    if (https.isNotEmpty && s.unClic) {
      if (!await _chiedi(
          titolo,
          'Chiedo al mittente di toglierti dalla sua lista con la disiscrizione in un clic, lo standard delle '
          'caselle email più diffuse. Il tuo account, se c\'è, non viene cancellato.',
          https,
          'Disiscrivimi')) {
        return;
      }
      if (!mounted) return;
      setState(() => _occupato = true);
      try {
        final codice = await inviaDisiscrizione(https, versione: (await PackageInfo.fromPlatform()).version);
        if (codice >= 400) throw 'errore $codice';
        await (await Archivio.apri()).impostaStato(s.dominio, stato: 'disiscritto');
        if (!mounted) return;
        setState(() => _stato = 'disiscritto');
        _messaggio('Richiesta inviata: ho chiesto a ${s.nome} di toglierti dalla lista. Di solito smettono di '
            'scrivere entro pochi giorni.');
      } on LinkNonAmmesso catch (e) {
        if (mounted) _messaggio('Non mando la richiesta: $e.');
      } catch (e) {
        if (!mounted) return;
        // la pagina si apre solo se l'utente lo chiede, mai da sola
        if (await _chiedi('Disiscrizione non riuscita',
            'Il mittente ha risposto con un errore ($e). Vuoi aprire la sua pagina di disiscrizione nel browser?',
            https, 'Apri la pagina')) {
          await launchUrl(Uri.parse(https), mode: LaunchMode.externalApplication);
        }
      } finally {
        if (mounted) setState(() => _occupato = false);
      }
    } else if (https.isNotEmpty) {
      if (!await _chiedi(titolo, 'Apro nel browser la pagina di disiscrizione indicata dal mittente.', https,
          'Apri la pagina')) {
        return;
      }
      await launchUrl(Uri.parse(https), mode: LaunchMode.externalApplication);
    } else if (mailto.isNotEmpty) {
      if (!await _chiedi(
          titolo,
          "Preparo nel tuo programma di posta l'email di disiscrizione indicata dal mittente: controllala e "
          'inviala tu.',
          mailto,
          "Prepara l'email")) {
        return;
      }
      await launchUrl(Uri.parse(mailto));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.servizio;
    final (https, mailto) = linkDisiscrizione(s.disiscrizione);
    final segnali = [
      if (s.acc > 0) 'benvenuto o conferma (${s.acc})',
      if (s.sic > 0) 'codici e password (${s.sic})',
      if (s.acq > 0) 'ordini e ricevute (${s.acq})',
      if (s.lst > 0) 'newsletter (${s.lst})',
    ];
    final cat = categorie[s.cat]!;
    return Scaffold(
      body: Column(
        children: [
          Testata(titolo: s.nome, sottotitolo: s.dominio, logo: false, indietro: () => Navigator.of(context).pop(true)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              children: [
                CardTk(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Pilla(cat.$1, coloriCategoria[s.cat]!, piena: false),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cat.$2, style: const TextStyle(color: grigio500, fontSize: 12.5))),
                      ]),
                      const SizedBox(height: 14),
                      _voce('Iscritto dal (prima email)', data(s.prima)),
                      _voce('Ultima email', data(s.ultima)),
                      _voce('Email ricevute', '${s.n}'),
                      _voce('Casella', s.caselle.map((i) => widget.caselle[i] ?? '?').join(', ')),
                      _voce('Segnali trovati', segnali.isEmpty ? 'nessuno: ti hanno solo scritto' : segnali.join(', ')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: (https.isEmpty && mailto.isEmpty) || _occupato ? null : _disiscriviti,
                  icon: const Icon(Icons.unsubscribe_outlined),
                  label: Text(https.isEmpty && mailto.isEmpty ? 'Nessun link per disiscriversi' : 'Disiscriviti'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse('https://duckduckgo.com/?q=${Uri.encodeQueryComponent('come cancellare account ${s.nome} ${s.dominio}')}'),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Come cancello l\'account?'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://${s.dominio}'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.public),
                  label: const Text('Apri il sito'),
                ),
                const SizedBox(height: 18),
                const TitoloSezione('Cosa ne fai?'),
                const SizedBox(height: 8),
                Row(children: [
                  for (final (k, t) in [('tenere', 'Tengo'), ('cancellare', 'Da cancellare'), ('fatto', 'Cancellato')])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: SizedBox(width: double.infinity, child: Text(t, textAlign: TextAlign.center)),
                          selected: _stato == k,
                          showCheckmark: false,
                          selectedColor: navy,
                          labelStyle: TextStyle(
                              color: _stato == k ? Colors.white : navy, fontWeight: FontWeight.w600, fontSize: 12.5),
                          onSelected: (_) => _salvaStato(k),
                        ),
                      ),
                    ),
                ]),
                if (_stato == 'disiscritto')
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Richiesta di disiscrizione inviata con tk-iscrizioni',
                        style: TextStyle(color: grigio500, fontSize: 12.5)),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nota,
                  decoration: const InputDecoration(hintText: 'Una nota (es. «account di lavoro»)'),
                  onEditingComplete: _salvaNota,
                  onTapOutside: (_) {
                    _salvaNota();
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 18),
                const TitoloSezione('Ultime email'),
                const SizedBox(height: 8),
                CardTk(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (final m in _ultime)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${data((m['ts'] as num).toDouble())} · ${m['from_addr']}',
                                style: const TextStyle(color: grigio500, fontSize: 11.5)),
                            const SizedBox(height: 2),
                            Text('${m['subject']}'.isEmpty ? '(senza oggetto)' : '${m['subject']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _voce(String etichetta, String valore) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(etichetta.toUpperCase(),
              style: const TextStyle(color: grigio500, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(valore, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
        ]),
      );
}
