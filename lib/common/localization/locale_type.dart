import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

enum LocaleType {
  system(null),
  en(Locale('en', 'GB')),
  ru(Locale('ru'));

  final Locale? value;

  const LocaleType(this.value);

  factory LocaleType.fromString(String value) => values.firstWhere((e) => e.name == value);

  static LocaleType? fromLocale(Locale locale) =>
      values.firstWhereOrNull((e) => e.value?.languageCode == locale.languageCode);
}
