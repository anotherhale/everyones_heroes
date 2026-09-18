import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/features/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/add_reflection_response_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/submit_reflection_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/emoji_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_emotion.dart';
import 'package:everyonesheroes/features/life_journey/presentation/providers/today_experience_provider.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({
    this.reflectionId,
    this.pendingReflection,
    super.key,
  });

  /// Ready reflection id (tab entry, tests, or already-created reflection).
  final ReflectionId? reflectionId;

  /// In-flight Begin Experience create. UI paints immediately; save waits
  /// until this resolves. Used when Reflect is pushed from Today's Experience.
  final Future<Result<Reflection>>? pendingReflection;

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  ReflectionId? _activeReflectionId;
  String? _prepareError;
  bool _isPreparing = false;

  String? _selectedFeeling;
  String? _confirmationMessage;
  bool _isSaving = false;

  static const _feelings = <_FeelingOption>[
    _FeelingOption(
      emoji: '💪',
      label: 'Strong',
      emotion: ReflectionEmotion.proud,
    ),
    _FeelingOption(
      emoji: '🌱',
      label: 'Growing',
      emotion: ReflectionEmotion.hopeful,
    ),
    _FeelingOption(
      emoji: '🔥',
      label: 'Motivated',
      emotion: ReflectionEmotion.excited,
    ),
    _FeelingOption(
      emoji: '🧘',
      label: 'Peaceful',
      emotion: ReflectionEmotion.calm,
    ),
    _FeelingOption(
      emoji: '❤️',
      label: 'Grateful',
      emotion: ReflectionEmotion.grateful,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeReflectionId = widget.reflectionId;

    final pending = widget.pendingReflection;
    if (pending != null && _activeReflectionId == null) {
      _isPreparing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolvePendingReflection(pending);
      });
    }
  }

  Future<void> _resolvePendingReflection(
    Future<Result<Reflection>> pending,
  ) async {
    final result = await pending;

    if (!mounted) {
      return;
    }

    result.fold(
      onSuccess: (reflection) {
        setState(() {
          _activeReflectionId = reflection.id;
          _isPreparing = false;
          _prepareError = null;
        });
      },
      onFailure: (error) {
        setState(() {
          _isPreparing = false;
          _prepareError = error;
        });
      },
    );
  }

  void _selectFeeling(String feeling) {
    if (_isSaving) {
      return;
    }

    setState(() {
      _selectedFeeling = feeling;
      _confirmationMessage = null;
    });
  }

  Future<void> _saveReflection() async {
    final reflectionId = _activeReflectionId;
    final selectedFeeling = _selectedFeeling;

    if (reflectionId == null || selectedFeeling == null || _isSaving) {
      return;
    }

    final feeling = _feelings.firstWhere(
      (option) => option.label == selectedFeeling,
    );

    setState(() {
      _isSaving = true;
      _confirmationMessage = null;
    });

    final addResponseResult = await ref
        .read(addReflectionResponseUseCaseProvider)
        .execute(
          reflectionId: reflectionId,
          response: EmojiResponse(emotion: feeling.emotion),
        );

    if (!mounted) {
      return;
    }

    final responseAdded = addResponseResult.fold(
      onSuccess: (_) => true,
      onFailure: (error) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));

        return false;
      },
    );

    if (!responseAdded) {
      return;
    }

    final submitResult = await ref
        .read(submitReflectionUseCaseProvider)
        .execute(SubmitReflectionRequest(reflectionId: reflectionId));

    if (!mounted) {
      return;
    }

    submitResult.fold(
      onSuccess: (_) {
        // UI.3: after submit → H.2 pipeline → Experience State Refresh on Home.
        ref.invalidate(todayExperienceProvider);

        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
          return;
        }

        setState(() {
          _isSaving = false;
          _confirmationMessage = 'Reflection saved: $selectedFeeling';
        });
      },
      onFailure: (error) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final reflectionReady = _activeReflectionId != null;

    final body = SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(24, canPop ? 16 : 28, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!canPop) ...[
                  Text(
                    'Reflect',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Take a moment.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isPreparing) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
                if (_prepareError != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _prepareError!,
                    key: const Key('reflect-prepare-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  'How are you feeling about your journey?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MoodEmoji(emoji: '😞', label: 'Low', theme: theme),
                    _MoodEmoji(emoji: '😕', label: '', theme: theme),
                    _MoodEmoji(emoji: '😐', label: '', theme: theme),
                    _MoodEmoji(emoji: '🙂', label: '', theme: theme),
                    _MoodEmoji(emoji: '😊', label: 'Great', theme: theme),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  'What best describes this moment?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ..._feelings.map(
                  (feeling) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeelingTile(
                      feeling: feeling,
                      selected: _selectedFeeling == feeling.label,
                      theme: theme,
                      onTap: () => _selectFeeling(feeling.label),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('save-reflection'),
                  onPressed:
                      _selectedFeeling == null ||
                          _isSaving ||
                          !reflectionReady
                      ? null
                      : _saveReflection,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Reflection'),
                ),
                if (_confirmationMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _confirmationMessage!,
                    key: const Key('reflection-saved-confirmation'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  "You don't have to explain everything.\n"
                  'Sometimes noticing is enough.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );

    // Pushed from Today's Experience: Scaffold + AppBar back (same Navigator
    // pattern as ExperienceScreen). Tab entry cannot pop — keep tab chrome.
    if (!canPop) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reflect'),
      ),
      body: body,
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  const _MoodEmoji({
    required this.emoji,
    required this.label,
    required this.theme,
  });

  final String emoji;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 34)),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _FeelingOption {
  const _FeelingOption({
    required this.emoji,
    required this.label,
    required this.emotion,
  });

  final String emoji;
  final String label;
  final ReflectionEmotion emotion;
}

class _FeelingTile extends StatelessWidget {
  const _FeelingTile({
    required this.feeling,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final _FeelingOption feeling;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('feeling-${feeling.label.toLowerCase()}'),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Text(feeling.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feeling.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
