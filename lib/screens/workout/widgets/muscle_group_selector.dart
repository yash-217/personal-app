import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MuscleGroupSelector extends StatelessWidget {
  final List<String> initialMuscleGroups;
  final List<String> muscleGroupsList;
  final Function(List<String>) onNext;

  const MuscleGroupSelector({
    super.key,
    required this.initialMuscleGroups,
    required this.muscleGroupsList,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Create a local state manager for selection
    return _MuscleGroupSelectorContent(
      initialMuscleGroups: initialMuscleGroups,
      muscleGroupsList: muscleGroupsList,
      onNext: onNext,
    );
  }
}

class _MuscleGroupSelectorContent extends StatefulWidget {
  final List<String> initialMuscleGroups;
  final List<String> muscleGroupsList;
  final Function(List<String>) onNext;

  const _MuscleGroupSelectorContent({
    required this.initialMuscleGroups,
    required this.muscleGroupsList,
    required this.onNext,
  });

  @override
  State<_MuscleGroupSelectorContent> createState() =>
      _MuscleGroupSelectorContentState();
}

class _MuscleGroupSelectorContentState
    extends State<_MuscleGroupSelectorContent> {
  final List<String> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialMuscleGroups);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: widget.muscleGroupsList.map((group) {
              final selected = _selected.contains(group);
              final color = AppColors.getBodyPartColor(group);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(
                      alpha: selected ? 0.3 : 0.1,
                    ),
                    child: Icon(
                      selected ? Icons.check : Icons.fitness_center,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _capitalize(group),
                    style: theme.textTheme.titleSmall,
                  ),
                  selected: selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: selected
                        ? BorderSide(color: color, width: 2)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selected.remove(group);
                      } else {
                        _selected.add(group);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selected.isNotEmpty
                ? () => widget.onNext(_selected)
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text('Next (${_selected.length} selected)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }
}
