import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.style;

    return theme.buildPageBackground(
      child: Scaffold(
        appBar: theme.buildAppBar(context, AppLocalizations.of(context, 'change_language')),
        body: Column(
          children: [
            const SizedBox(height: ThemeStyle.defaultPadding),
            // Language selection header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeStyle.defaultPadding,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: theme.iconBoxDecoration(context),
                    child: Icon(
                      Icons.language,
                      color: Theme.of(context).primaryColor,
                      size: ThemeStyle.iconSize,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context, 'select_language'),
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeStyle.defaultPadding),
            // Language options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildLanguageItem(
                    context,
                    'English',
                    'English',
                    const Locale('en'),
                  ),
                  // Added new languages as requested
                  _buildLanguageItem(
                    context,
                    'ಕನ್ನಡ',
                    'Kannada',
                    const Locale('kn'),
                  ),
                  _buildLanguageItem(
                    context,
                    'தமிழ்',
                    'Tamil',
                    const Locale('ta'),
                  ),
                  _buildLanguageItem(
                    context,
                    'తెలుగు',
                    'Telugu',
                    const Locale('te'),
                  ),
                  _buildLanguageItem(
                    context,
                    'മലയാളം',
                    'Malayalam',
                    const Locale('ml'),
                  ),
                  _buildLanguageItem(
                    context,
                    'ଓଡ଼ିଆ',
                    'Odiya',
                    const Locale('or'),
                  ),
                  // Existing languages
                  _buildLanguageItem(
                    context,
                    'हिंदी',
                    'Hindi',
                    const Locale('hi'),
                  ),
                  _buildLanguageItem(
                    context,
                    'ગુજરાતી',
                    'Gujarati',
                    const Locale('gu'),
                  ),
                  _buildLanguageItem(
                    context,
                    'मराठी',
                    'Marathi',
                    const Locale('mr'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    String name,
    String englishName,
    Locale locale,
  ) {
    final provider = Provider.of<LocaleProvider>(context);
    final isSelected = provider.locale == locale;
    final theme = AppTheme.style;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: theme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeStyle.cardBorderRadius),
          ),
          title: Text(name, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black87)),
          subtitle: Text(englishName, style: const TextStyle(fontSize: 14.0, color: Colors.black54)),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
            ),
            child: Icon(
              Icons.check,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
          ),
          onTap: () {
            provider.setLocale(locale);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
