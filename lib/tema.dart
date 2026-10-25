// Colori e pezzi propri di tk-iscrizioni; tutto il resto (testata, card, dialoghi, Informazioni, splash) è nel kit comune.
import 'package:flutter/material.dart';

import 'kit_tk.dart';

export 'kit_tk.dart';

const accento = Color(0xFF7C3AED);
const accentoScuro = Color(0xFF6D28D9);
const accentoChiaro = Color(0xFFEDE9FE);
const accento2 = Color(0xFF8B5CF6);

const coloriCategoria = {
  'account': accento,
  'social': Color(0xFF2563EB),
  'acquisti': Color(0xFF059669),
  'newsletter': Color(0xFFD97706),
  'altro': grigio500,
  'persona': grigio400,
};

/// Simbolo di tk-iscrizioni: busta bianca col bollino bianco e la spunta viola.
Widget simboloIscrizioni(double lato) => SizedBox(
      width: lato,
      height: lato,
      child: CustomPaint(painter: PittoreLogo(fondo: false, bollino: bianco, spunta: accentoScuro, busta: accentoScuro)),
    );

const configIscrizioni = ConfigTk(
  nome: 'tk-iscrizioni',
  motto: 'La tua email in chiaro',
  descrizione: 'Iscrizioni email',
  accento: accento,
  accentoScuro: accentoScuro,
  simbolo: simboloIscrizioni,
  manifestUrl:
      'https://dl.dropboxusercontent.com/scl/fi/st1ecu78aut31pxahzt8s/tkiscrizioni-version.json?rlkey=68u56hyml7f2f0zk70vc67nfu',
  altrove: ("C'è anche per Windows e Mac", 'https://pietrodefilippis.it/software/'),
);

/// Nota sotto «I tuoi dati» in Informazioni.
const notaDatiInformazioni =
    'Restano su questo telefono: archivio delle intestazioni e password nella cassaforte del telefono.';

/// Righe di tk-iscrizioni nel benvenuto comune del primo avvio (come BENVENUTO_RIGHE del programma per computer).
/// Prima della 1.2.0 c'era una finestra di benvenuto dell'app: ora è una sola.
const righeBenvenuto = [
  '**Legge solo le intestazioni** (mittente, oggetto, data, link di disiscrizione), **in sola lettura**: nessuna '
      'email viene aperta, segnata come letta, spostata o cancellata.',
  "**Sul telefono** restano l'archivio di mittenti, oggetti e date delle email lette e le password delle caselle, "
      'nella cassaforte del telefono (Keystore su Android, Portachiavi su iPhone). Togliendo una casella si '
      'cancellano tutte e due.',
  "**In rete:** il tuo fornitore di posta; Dropbox per il controllo degli aggiornamenti (Android); "
      'pietrodefilippis.it per le statistiche, solo col sì qui sotto; i siti dei mittenti solo quando premi '
      '«Disiscriviti» o «Apri il sito». Email e password non passano da altri server.',
];

class PittoreLogo extends CustomPainter {
  PittoreLogo({this.fondo = true, this.bollino = accento2, this.spunta = Colors.white, this.busta = navy});

  /// fondo navy (icona dell'app); senza fondo è il simbolo bianco sul quadrato viola del kit
  final bool fondo;
  final Color bollino, spunta, busta;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (fondo) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * .24)),
        Paint()..shader = const LinearGradient(colors: [navy2, navy]).createShader(Offset.zero & size),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * .15, s * .26, s * .62, s * .44), Radius.circular(s * .06)),
      Paint()..color = Colors.white,
    );
    final tratto = Paint()
      ..color = busta
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
        Path()
          ..moveTo(s * .19, s * .31)
          ..lineTo(s * .46, s * .51)
          ..lineTo(s * .73, s * .31),
        tratto);
    canvas.drawCircle(Offset(s * .74, s * .72), s * .17, Paint()..color = bollino);
    canvas.drawPath(
      Path()
        ..moveTo(s * .66, s * .72)
        ..lineTo(s * .72, s * .78)
        ..lineTo(s * .83, s * .66),
      Paint()
        ..color = spunta
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String data(double ts) {
  if (ts <= 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch((ts * 1000).round());
  String due(int n) => n.toString().padLeft(2, '0');
  return '${due(d.day)}/${due(d.month)}/${d.year}';
}
