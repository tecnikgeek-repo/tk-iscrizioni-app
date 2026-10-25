# tk-iscrizioni per Android e iPhone

Scopri a quali siti, servizi e newsletter sei iscritto con la tua email: l'app legge solo le intestazioni delle
email (mittente, oggetto, data, link di disiscrizione), in sola lettura, e ti mostra da quando sei iscritto e come
uscirne. Tutte le funzioni sono gratis, per tutti.

- **Piattaforme:** Android (APK) e iPhone. C'è anche per Windows e Mac: [tk-iscrizioni per computer](https://pietrodefilippis.it/software/).
- **Licenza:** software libero sotto [GNU AGPL-3.0](COPYING), fornito così com'è, senza alcuna garanzia.
- **Privacy:** l'archivio delle intestazioni e le password delle caselle (nella cassaforte del telefono) restano sul
  telefono. In rete: il tuo fornitore di posta; Dropbox per il controllo degli aggiornamenti (Android); i siti dei
  mittenti solo quando premi «Disiscriviti». Le statistiche anonime (una volta al giorno: nome, versione, sistema e
  un codice casuale) partono solo se dici sì nel benvenuto o in Informazioni.
- **Disiscrizione sicura:** il link di disiscrizione si usa solo se l'email ha la firma DKIM verificata del
  mittente; prima di aprirlo l'app mostra dove porta, e la richiesta in un clic va solo in https verso siti pubblici.

## Compilare dal sorgente

Serve [Flutter](https://flutter.dev) (versione indicata in `.github/workflows/android.yml`):

```
flutter pub get
flutter test
flutter build apk --release
```

Senza la variabile `ANDROID_KEYSTORE` l'APK si firma con la chiave di debug di Flutter.

Il nome «tk-iscrizioni» e il logo non sono coperti dalla licenza (AGPL sez. 7): una versione modificata deve avere
un nome diverso.

© 2026 Pietro De Filippis (TecnikGeek) — [pietrodefilippis.it](https://pietrodefilippis.it)
