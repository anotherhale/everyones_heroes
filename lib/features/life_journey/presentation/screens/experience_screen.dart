import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/life_journey/application/providers/use_cases/begin_experience_use_case_provider.dart';
import 'package:everyonesheroes/features/life_journey/presentation/models/today_experience_view_model.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

final class ExperienceScreen extends ConsumerStatefulWidget {
  const ExperienceScreen({required this.experience, super.key});

  final TodayExperienceViewModel experience;

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

final class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  bool _isBeginning = false;

  Future<void> _beginExperience() async {
    if (_isBeginning) {
      return;
    }

    setState(() {
      _isBeginning = true;
    });

    final result = await ref
        .read(beginExperienceUseCaseProvider)
        .execute(action: widget.experience.action);

    if (!mounted) {
      return;
    }

    result.fold(
      onSuccess: (reflection) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReflectScreen(reflectionId: reflection.id),
          ),
        );
      },
      onFailure: (error) {
        setState(() {
          _isBeginning = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Experience")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.experience.title,
                key: const ValueKey('experience-title'),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                widget.experience.description,
                key: const ValueKey('experience-description'),
                style: theme.textTheme.bodyLarge,
              ),
              if (widget.experience.rationale != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.experience.rationale!,
                      key: const ValueKey('experience-rationale'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                key: const ValueKey('begin-experience-button'),
                onPressed: _isBeginning ? null : _beginExperience,
                child: _isBeginning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.experience.callToAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
