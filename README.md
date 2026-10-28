<!-- README generato da Dropbox/CLAUDE/dev/agpl-rollout/readme/genera_readme_app.py: modificare lì -->
<div align="center">

<img src="docs/vetrina.png" alt="tk-iscrizioni: A cosa sei iscritto? Scoprilo." width="100%">

<br><br>

<a href="https://pietrodefilippis.it/scarica-app/tk-iscrizioni-app/"><img alt="Scarica l'app" src="https://img.shields.io/badge/%E2%AC%87%20%20Scarica-gratis%20per%20Android-7c3aed?style=for-the-badge&logo=android&logoColor=white"></a> &nbsp; <a href="https://pietrodefilippis.it/donazione/"><img alt="Offrimi un caffè" src="https://img.shields.io/badge/%E2%98%95%20%20Offrimi%20un%20caff%C3%A8-facoltativo-f59e0b?style=for-the-badge"></a>

<br><br>

<a href="COPYING"><img alt="Licenza AGPL-3.0" src="https://img.shields.io/badge/licenza-AGPL--3.0-16a34a?style=for-the-badge"></a> <img alt="Android" src="https://img.shields.io/badge/Android-telefono%20%C2%B7%20tablet-3DDC84?style=for-the-badge&logo=android&logoColor=white"> <img alt="Versione" src="https://img.shields.io/github/v/tag/tecnikgeek-repo/tk-iscrizioni-app?label=versione&style=for-the-badge&color=7c3aed"> <img alt="Zero pubblicità" src="https://img.shields.io/badge/pubblicit%C3%A0-zero-0f172a?style=for-the-badge">

</div>

---

## ✨ Cosa fa

<table>
<tr>
<td width="50%" valign="top">

### 📬&nbsp; La tua casella
L'app legge solo le intestazioni delle email (mittente, oggetto, data), in sola lettura.

</td>
<td width="50%" valign="top">

### 🧭&nbsp; Servizi trovati
Divisi per tipo: account, social, acquisti, newsletter.

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 📅&nbsp; Da quando
Per ogni servizio vedi da quando sei iscritto.

</td>
<td width="50%" valign="top">

### 🚪&nbsp; Disiscriviti
Esci dalle newsletter e dai servizi che non vuoi più.

</td>
</tr>
<tr>
<td width="50%" valign="top">

### ✅&nbsp; Solo email autentiche
Il link di disiscrizione si usa solo se l'email ha la firma DKIM verificata del mittente.

</td>
<td width="50%" valign="top">

### 👀&nbsp; Niente sorprese
Prima di aprire un link l'app ti mostra dove porta.

</td>
</tr>
</table>

## 📱 Com'è fatta

<div align="center">

<table align="center">
<tr>
<td align="center" valign="top"><img src="docs/schermata-1.png" width="200" alt="Servizi"><br><sub><b>Servizi</b></sub></td>
<td align="center" valign="top"><img src="docs/schermata-2.png" width="200" alt="Servizio"><br><sub><b>Servizio</b></sub></td>
<td align="center" valign="top"><img src="docs/schermata-3.png" width="200" alt="Aggiungi casella"><br><sub><b>Aggiungi casella</b></sub></td>
</tr>
</table>

</div>

## 🔒 I tuoi dati

- **Privacy:** l'archivio delle intestazioni e le password delle caselle (nella cassaforte del telefono) restano sul telefono. In rete: il tuo fornitore di posta; Dropbox per il controllo degli aggiornamenti (Android); i siti dei mittenti solo quando premi «Disiscriviti». Le statistiche anonime (una volta al giorno: nome, versione, sistema e un codice casuale) partono solo se dici sì nel benvenuto o in Informazioni.
- **Disiscrizione sicura:** il link di disiscrizione si usa solo se l'email ha la firma DKIM verificata del mittente; prima di aprirlo l'app mostra dove porta, e la richiesta in un clic va solo in https verso siti pubblici.

Nessuna pubblicità, nessun account da creare, nessun abbonamento: tutte le funzioni sono gratis, per tutti.

## 📥 Installazione

- **Android** — [scarica l'app](https://pietrodefilippis.it/scarica-app/tk-iscrizioni-app/) da pietrodefilippis.it e aprila: Android chiede una volta il permesso di installare app da questa origine. Gli aggiornamenti arrivano da soli, l'app te li propone. A breve anche su Google Play.
- **Piattaforme:** Android e iPhone. C'è anche per Windows e Mac: [tk-iscrizioni per computer](https://pietrodefilippis.it/software/).

<details>
<summary><b>🛠️ Compilare dal codice sorgente</b></summary>

<br>

Serve [Flutter](https://flutter.dev) (versione indicata in `.github/workflows/android.yml`):

```bash
flutter pub get
flutter test
flutter build apk --release
```

Senza la variabile `ANDROID_KEYSTORE` l'APK si firma con la chiave di debug di Flutter.

</details>

## 📜 Licenza

**tk-iscrizioni** è software libero: © 2026 Pietro De Filippis (TecnikGeek), licenza
**[GNU Affero General Public License v3.0](COPYING)**. Puoi usarlo, studiarlo, modificarlo e condividerlo; è
fornito **così com'è, senza alcuna garanzia**.

> Il nome **tk-iscrizioni** e il logo non sono coperti dalla licenza (AGPL, sezione 7): una versione modificata deve avere un nome diverso.

---

<div align="center">

**Ti è utile?** Tutte le funzioni sono gratis per tutti. Se vuoi, un caffè aiuta a migliorarla e a crearne altre.

<a href="https://pietrodefilippis.it/donazione/"><img alt="Offrimi un caffè" src="https://img.shields.io/badge/%E2%98%95%20%20Offrimi%20un%20caff%C3%A8-pietrodefilippis.it-f59e0b?style=for-the-badge"></a>

<sub>Creata da <a href="https://pietrodefilippis.it">Pietro De Filippis · TecnikGeek</a> — Webmaster & UX/UI Designer</sub>

</div>
