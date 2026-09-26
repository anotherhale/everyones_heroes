import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/my_hero_profile_view_model.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/my_hero_profile_providers.dart';

/// Owner-facing authoring for existing HeroProfile fields (HP.1 / HP.2).
///
/// Edits the active local Hero aggregate — not a separate MyHeroProfile model.
/// Discoverability remains controlled separately on My Stories.
class MyHeroProfileScreen extends ConsumerStatefulWidget {
  const MyHeroProfileScreen({super.key});

  @override
  ConsumerState<MyHeroProfileScreen> createState() =>
      _MyHeroProfileScreenState();
}

class _MyHeroProfileScreenState extends ConsumerState<MyHeroProfileScreen> {
  final _displayNameController = TextEditingController();
  final _biographyController = TextEditingController();
  final _experienceAreasController = TextEditingController();
  final _geographicContextController = TextEditingController();
  final _customLanguageController = TextEditingController();

  String? _boundHeroId;
  Set<String> _selectedLanguageCodes = <String>{};
  String? _languageFieldError;

  /// Common LanguageCode values offered as toggles (not a second language model).
  static const _suggestedLanguageCodes = <String>[
    'en',
    'es',
    'fr',
    'de',
    'pt',
    'it',
    'ja',
    'zh',
    'ko',
    'ar',
    'hi',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _biographyController.dispose();
    _experienceAreasController.dispose();
    _geographicContextController.dispose();
    _customLanguageController.dispose();
    super.dispose();
  }

  void _bindForm(MyHeroProfileViewModel model) {
    if (_boundHeroId == model.heroId.value) {
      return;
    }
    _boundHeroId = model.heroId.value;
    _displayNameController.text = model.displayName;
    _biographyController.text = model.biography ?? '';
    _experienceAreasController.text = model.experienceAreas.join(', ');
    _geographicContextController.text = model.geographicContext ?? '';
    _selectedLanguageCodes = {
      for (final language in model.languages) language.value,
    };
  }

  List<String> _parseExperienceAreas(String raw) {
    return raw
        .split(RegExp(r'[,;\n]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  List<LanguageCode> _selectedLanguages() {
    return [
      for (final code in _selectedLanguageCodes) LanguageCode(code),
    ];
  }

  void _toggleLanguage(String code) {
    setState(() {
      _languageFieldError = null;
      if (_selectedLanguageCodes.contains(code)) {
        _selectedLanguageCodes = {..._selectedLanguageCodes}..remove(code);
      } else {
        _selectedLanguageCodes = {..._selectedLanguageCodes, code};
      }
    });
  }

  void _addCustomLanguage() {
    final raw = _customLanguageController.text.trim();
    if (raw.isEmpty) {
      return;
    }
    try {
      final code = LanguageCode(raw);
      setState(() {
        _languageFieldError = null;
        _selectedLanguageCodes = {..._selectedLanguageCodes, code.value};
        _customLanguageController.clear();
      });
    } on ArgumentError catch (e) {
      setState(() {
        _languageFieldError = e.message?.toString() ?? e.toString();
      });
    }
  }

  Future<void> _save() async {
    final controller = ref.read(myHeroProfileControllerProvider.notifier);
    final ok = await controller.save(
      displayName: _displayNameController.text,
      biography: _biographyController.text,
      experienceAreas: _parseExperienceAreas(_experienceAreasController.text),
      languages: _selectedLanguages(),
      geographicContext: _geographicContextController.text,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      // Allow form rebinding from refreshed provider data.
      _boundHeroId = null;
      final refreshed = await ref.read(myHeroProfileProvider.future);
      if (!mounted) {
        return;
      }
      setState(() => _bindForm(refreshed));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: ValueKey('my-hero-profile-saved-snackbar'),
          content: Text('Profile saved'),
        ),
      );
      controller.clearSavedFlag();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(myHeroProfileProvider);
    final action = ref.watch(myHeroProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hero Profile'),
        key: const ValueKey('my-hero-profile-app-bar'),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            key: ValueKey('my-hero-profile-loading'),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to load your hero profile.',
                  key: const ValueKey('my-hero-profile-load-error'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const ValueKey('my-hero-profile-retry'),
                  onPressed: () => ref.invalidate(myHeroProfileProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (model) {
          _bindForm(model);
          return SingleChildScrollView(
            key: const ValueKey('my-hero-profile-form'),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                'Your Hero Profile',
                key: const ValueKey('my-hero-profile-heading'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Factual profile information for your Hero. '
                'Discoverability is controlled separately on My Stories.',
                key: const ValueKey('my-hero-profile-subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const ValueKey('my-hero-profile-display-name'),
                controller: _displayNameController,
                enabled: !action.isBusy,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Required',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('my-hero-profile-biography'),
                controller: _biographyController,
                enabled: !action.isBusy,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Biography',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('my-hero-profile-experience-areas'),
                controller: _experienceAreasController,
                enabled: !action.isBusy,
                decoration: const InputDecoration(
                  labelText: 'Experience areas',
                  hintText: 'Comma-separated, e.g. Military, Parenting',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Languages',
                key: const ValueKey('my-hero-profile-languages-label'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('my-hero-profile-languages'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in {
                    ..._suggestedLanguageCodes,
                    ..._selectedLanguageCodes,
                  })
                    FilterChip(
                      key: ValueKey('my-hero-profile-language-$code'),
                      label: Text(code.toUpperCase()),
                      selected: _selectedLanguageCodes.contains(code),
                      onSelected: action.isBusy
                          ? null
                          : (_) => _toggleLanguage(code),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('my-hero-profile-language-custom'),
                      controller: _customLanguageController,
                      enabled: !action.isBusy,
                      decoration: const InputDecoration(
                        labelText: 'Add language code',
                        hintText: 'e.g. en-us',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addCustomLanguage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      key: const ValueKey('my-hero-profile-language-add'),
                      onPressed: action.isBusy ? null : _addCustomLanguage,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              if (_languageFieldError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _languageFieldError!,
                  key: const ValueKey('my-hero-profile-language-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('my-hero-profile-geographic-context'),
                controller: _geographicContextController,
                enabled: !action.isBusy,
                decoration: const InputDecoration(
                  labelText: 'Geographic context',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              if (action.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  action.errorMessage!,
                  key: const ValueKey('my-hero-profile-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const ValueKey('my-hero-profile-dismiss-error'),
                    onPressed: () => ref
                        .read(myHeroProfileControllerProvider.notifier)
                        .clearError(),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('my-hero-profile-save'),
                onPressed: action.isBusy ? null : _save,
                child: Text(action.isBusy ? 'Saving…' : 'Save Profile'),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}
