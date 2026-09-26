import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _lexendLicenseAsset = 'assets/licenses/Lexend-OFL-1.1.txt';
const String _atkinsonLicenseAsset =
    'assets/licenses/AtkinsonHyperlegible-OFL-1.1.txt';

Future<void> registerEyesFontLicenses() async {
  final licenses = await Future.wait(<Future<({String package, String text})>>[
    _loadLicense('Lexend', _lexendLicenseAsset),
    _loadLicense('Atkinson Hyperlegible', _atkinsonLicenseAsset),
  ]);

  for (final license in licenses) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(<String>[license.package], license.text);
    });
  }
}

Future<({String package, String text})> _loadLicense(
  String package,
  String asset,
) async => (package: package, text: await rootBundle.loadString(asset));
