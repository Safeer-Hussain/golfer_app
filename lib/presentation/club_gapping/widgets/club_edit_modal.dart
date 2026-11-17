import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/club_model.dart';

class ClubEditModal extends StatefulWidget {
  final ClubModel club;
  final Function(int carryYards, int totalYards) onSave;

  const ClubEditModal({super.key, required this.club, required this.onSave});

  @override
  State<ClubEditModal> createState() => _ClubEditModalState();
}

class _ClubEditModalState extends State<ClubEditModal> {
  late int _carryYards;
  late int _totalYards;

  @override
  void initState() {
    super.initState();
    _carryYards = widget.club.carryYards;
    _totalYards = widget.club.totalYards;
  }

  void _save() {
    if (_carryYards <= 0 || _totalYards <= 0) {
      AppFeedback.showError(context, 'Distance must be greater than zero.');
      return;
    }
    if (_totalYards < _carryYards) {
      _totalYards = _carryYards;
    }

    widget.onSave(_carryYards, _totalYards);
    Navigator.of(context).pop();
    AppFeedback.showSuccess(
      context,
      'Updated ${widget.club.name}: ${_carryYards}y carry / ${_totalYards}y total',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_road_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calibrate ${widget.club.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${widget.club.category} • Loft ${widget.club.loft}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDistanceAdjuster(
              context,
              label: 'Carry Distance (Air Travel)',
              value: _carryYards,
              onDecrement: () {
                if (_carryYards > 20) {
                  setState(() {
                    _carryYards -= 5;
                    if (_totalYards < _carryYards) _totalYards = _carryYards;
                  });
                }
              },
              onIncrement: () {
                if (_carryYards < 360) {
                  setState(() {
                    _carryYards += 5;
                    if (_totalYards < _carryYards) {
                      _totalYards = _carryYards + 5;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            _buildDistanceAdjuster(
              context,
              label: 'Total Distance (Carry + Roll)',
              value: _totalYards,
              onDecrement: () {
                if (_totalYards > _carryYards) {
                  setState(() {
                    _totalYards -= 5;
                  });
                }
              },
              onIncrement: () {
                if (_totalYards < 390) {
                  setState(() {
                    _totalYards += 5;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Calibration'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceAdjuster(
    BuildContext context, {
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove_rounded, size: 20),
                onPressed: onDecrement,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  '$value yds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded, size: 20),
                onPressed: onIncrement,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
