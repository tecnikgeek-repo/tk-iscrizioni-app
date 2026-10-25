// Password e token delle caselle: cifrati sul telefono (Keystore su Android, Portachiavi su iPhone).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _cassaforte = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

Future<void> salvaSegreto(String email, String segreto) => _cassaforte.write(key: 'casella:$email', value: segreto);

Future<String?> leggiSegreto(String email) => _cassaforte.read(key: 'casella:$email');

Future<void> cancellaSegreto(String email) => _cassaforte.delete(key: 'casella:$email');
