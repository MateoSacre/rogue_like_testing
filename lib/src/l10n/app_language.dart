/// Supported UI languages.
///
/// The native label is intentionally NOT translated (a language is always
/// shown in its own language in pickers).
enum AppLanguage {
  fr('Français'),
  en('English');

  const AppLanguage(this.nativeLabel);

  final String nativeLabel;

  static AppLanguage fromName(String? name) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == name,
      orElse: () => AppLanguage.fr,
    );
  }
}
