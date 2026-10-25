// Aggiungere una casella: indirizzo, fornitore riconosciuto da solo, password (o accesso Microsoft).
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'archivio.dart';
import 'credenziali.dart';
import 'fornitori.dart';
import 'posta.dart';
import 'tema.dart';

class SchermataAggiungi extends StatefulWidget {
  const SchermataAggiungi({super.key});

  @override
  State<SchermataAggiungi> createState() => _SchermataAggiungiState();
}

class _SchermataAggiungiState extends State<SchermataAggiungi> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _host = TextEditingController();
  final _porta = TextEditingController(text: '993');
  Fornitore _fornitore = fornitori.first;
  bool _manuale = false;
  bool _mostra = false;
  bool _server = false;
  bool _occupato = false;
  String _errore = '';

  @override
  void initState() {
    super.initState();
    _email.addListener(_emailCambiata);
    _scegli(fornitori.first, manuale: false);
  }

  void _emailCambiata() {
    final t = _email.text;
    final f = riconosci(t);
    final dom = t.trim().split('@').last;
    if (f != null) {
      if (f.chiave != _fornitore.chiave) _scegli(f, manuale: false);
    } else if (t.contains('@') && dom.contains('.') && !_manuale) {
      if (_fornitore.chiave != 'altro') _scegli(fornitore('altro'), manuale: false);
      _host.text = hostProbabile(t);
    } else if (_fornitore.chiave == 'altro') {
      _host.text = hostProbabile(t);
    }
  }

  void _scegli(Fornitore f, {required bool manuale}) {
    setState(() {
      _fornitore = f;
      if (manuale) _manuale = true;
      _host.text = f.host.isNotEmpty ? f.host : hostProbabile(_email.text);
      _porta.text = '${f.port}';
      _server = f.chiave == 'altro';
      _errore = '';
    });
  }

  Future<void> _salva() async {
    final e = _email.text.trim().toLowerCase();
    if (!e.contains('@') || !e.split('@').last.contains('.')) return setState(() => _errore = 'Scrivi un indirizzo email valido.');
    if (_fornitore.oauth) {
      return setState(() => _errore = 'Le caselle Outlook e Hotmail arrivano con un prossimo aggiornamento: stiamo '
          'completando la registrazione presso Microsoft.');
    }
    var pw = _password.text;
    if (pw.isEmpty) return setState(() => _errore = 'Scrivi la password.');
    if (_fornitore.chiave == 'gmail') pw = pw.replaceAll(' ', '');
    final host = _host.text.trim();
    final porta = int.tryParse(_porta.text.trim()) ?? 993;
    if (host.isEmpty) return setState(() => _errore = 'Scrivi il server IMAP.');
    setState(() {
      _occupato = true;
      _errore = '';
    });
    try {
      final client = await collega(host, porta, e, pw);
      await cartelle(client);
      try {
        await client.logout();
        await client.disconnect();
      } catch (_) {}
      await salvaSegreto(e, pw);
      final archivio = await Archivio.apri();
      await archivio.aggiungiCasella(e, _fornitore.chiave, host, porta, 'password');
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      var m = '$err'.replaceFirst('Exception: ', '');
      if (['gmail', 'yahoo', 'icloud'].contains(_fornitore.chiave)) {
        m += '\nServe la password per le app, non quella con cui entri nel sito.';
      }
      setState(() {
        _occupato = false;
        _errore = 'Non riesco a entrare: $m';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _fornitore;
    return Scaffold(
      body: Column(
        children: [
          Testata(
              logo: false,
              titolo: 'Aggiungi una casella',
              sottotitolo: 'Le credenziali restano cifrate su questo telefono',
              indietro: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              children: [
                CardTk(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TitoloSezione('Indirizzo email'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(hintText: 'nome@esempio.it'),
                      ),
                      const SizedBox(height: 14),
                      const TitoloSezione('Fornitore'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: f.chiave,
                        key: ValueKey(f.chiave),
                        isExpanded: true,
                        items: [for (final x in fornitori) DropdownMenuItem(value: x.chiave, child: Text(x.nome))],
                        onChanged: (k) => _scegli(fornitore(k!), manuale: true),
                      ),
                      const SizedBox(height: 10),
                      Text(f.aiuto, style: const TextStyle(color: grigio500, fontSize: 13.5, height: 1.35)),
                      if (f.linkAiuto.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => launchUrl(Uri.parse(f.linkAiuto), mode: LaunchMode.externalApplication),
                            child: Text('${f.testoLink}  →',
                                style: const TextStyle(color: accentoScuro, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (f.oauth)
                        FilledButton.icon(
                          onPressed: _salva,
                          icon: const Icon(Icons.window),
                          label: const Text('Accedi con Microsoft'),
                        )
                      else ...[
                        TitoloSezione(f.etichettaPassword.isEmpty ? 'Password della casella' : f.etichettaPassword),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _password,
                          obscureText: !_mostra,
                          autocorrect: false,
                          enableSuggestions: false,
                          onSubmitted: (_) => _salva(),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(_mostra ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _mostra = !_mostra),
                            ),
                          ),
                        ),
                        if (!_server)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: () => setState(() => _server = true),
                                child: const Text('Server e porta', style: TextStyle(color: accentoScuro))),
                          ),
                        if (_server) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const TitoloSezione('Server IMAP'),
                                const SizedBox(height: 6),
                                TextField(controller: _host, autocorrect: false),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 90,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const TitoloSezione('Porta'),
                                const SizedBox(height: 6),
                                TextField(controller: _porta, keyboardType: TextInputType.number),
                              ]),
                            ),
                          ]),
                        ],
                      ],
                      if (_errore.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                          child: Text(_errore,
                              style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600)),
                        ),
                      ],
                      if (!f.oauth) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _occupato ? null : _salva,
                          icon: _occupato
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                          label: Text(_occupato ? 'Provo l\'accesso…' : 'Prova e salva'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(children: [
                  Icon(Icons.lock_outline, size: 16, color: grigio500),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        'Email e password non passano da altri server: l\'app si collega direttamente al tuo '
                        'fornitore di posta, in sola lettura.',
                        style: TextStyle(color: grigio500, fontSize: 12.5)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
