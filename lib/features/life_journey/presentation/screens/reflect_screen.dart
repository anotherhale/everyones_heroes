import 'package:flutter/material.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  String? _selectedFeeling;
  String? _confirmationMessage;
  static const _feelings = <_FeelingOption>[
    _FeelingOption(emoji: '💪', label: 'Strong'),
    _FeelingOption(emoji: '🌱', label: 'Growing'),
    _FeelingOption(emoji: '🔥', label: 'Motivated'),
    _FeelingOption(emoji: '🧘', label: 'Peaceful'),
    _FeelingOption(emoji: '❤️', label: 'Grateful'),
  ];

  void _selectFeeling(String feeling) {
    setState(() {
      _selectedFeeling = feeling;
    });
  }

  void _saveReflection() {
    final feeling = _selectedFeeling;
    if (feeling == null) {
      return;
    }

    setState(() {
      _confirmationMessage = 'Reflection saved: $feeling';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Reflect',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a moment.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                  onPressed: _selectedFeeling == null ? null : _saveReflection,
                  child: const Text('Save Reflection'),
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
  const _FeelingOption({required this.emoji, required this.label});

  final String emoji;
  final String label;
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
