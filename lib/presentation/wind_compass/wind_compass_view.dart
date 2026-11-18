import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/app_feedback.dart';
import '../../domain/entities/wind_compass_entity.dart';
import 'wind_compass_controller.dart';
import 'widgets/aim_adjustment_card.dart';
import 'widgets/compass_rose_hud.dart';
import 'widgets/wind_presets_modal.dart';
import 'widgets/wind_vector_cockpit_card.dart';

class WindCompassView extends StatefulWidget {
  const WindCompassView({super.key});

  @override
  State<WindCompassView> createState() => _WindCompassViewState();
}

class _WindCompassViewState extends State<WindCompassView> {
  late final WindCompassController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = sl<WindCompassController>();
    _controller.loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final resolution = _controller.currentResolution;
        final unit = _controller.speedUnit;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Wind Vector Compass HUD'),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Select Wind Preset',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {
                  WindPresetsModal.show(
                    context,
                    onSelectPreset: (preset) {
                      _controller.applyPreset(preset);
                      AppFeedback.showSuccess(
                        context,
                        'Applied preset: ${preset.name}',
                      );
                    },
                  );
                },
              ),
              IconButton(
                tooltip: 'Calculation History',
                icon: const Icon(Icons.history_rounded),
                onPressed: () => _showHistoryModal(context),
              ),
              IconButton(
                tooltip: 'Reset to Defaults',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  _controller.resetToDefaults();
                  AppFeedback.showInfo(context, 'Reset to standard defaults');
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'windCompassSaveFab',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Log Shot Vector'),
            onPressed: () async {
              await _controller.saveCurrentResolution();
              if (context.mounted) {
                AppFeedback.showSuccess(
                  context,
                  'Logged vector: ${resolution.distanceRecommendation}',
                );
              }
            },
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return _buildLandscapeLayout(context, resolution, unit);
              }
              return _buildPortraitLayout(context, resolution, unit);
            },
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WindVectorResolution resolution,
    WindSpeedUnit unit,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompassRoseHud(resolution: resolution, size: 240),
          const SizedBox(height: 16),
          WindVectorCockpitCard(resolution: resolution, unit: unit),
          const SizedBox(height: 12),
          AimAdjustmentCard(resolution: resolution, unit: unit),
          const SizedBox(height: 16),
          _buildControlsCard(context, resolution, unit),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WindVectorResolution resolution,
    WindSpeedUnit unit,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Compass HUD + Key Metrics
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 80),
            child: Column(
              children: [
                CompassRoseHud(resolution: resolution, size: 190),
                const SizedBox(height: 12),
                WindVectorCockpitCard(resolution: resolution, unit: unit),
              ],
            ),
          ),
        ),
        // Right Column: Aim Strategy + Controls
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 80),
            child: Column(
              children: [
                AimAdjustmentCard(resolution: resolution, unit: unit),
                const SizedBox(height: 12),
                _buildControlsCard(context, resolution, unit),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsCard(
    BuildContext context,
    WindVectorResolution resolution,
    WindSpeedUnit unit,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Target & Wind Calibration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Speed Unit Selector
            Center(
              child: SegmentedButton<WindSpeedUnit>(
                segments: const [
                  ButtonSegment(
                    value: WindSpeedUnit.knots,
                    label: Text('Knots'),
                  ),
                  ButtonSegment(value: WindSpeedUnit.mph, label: Text('MPH')),
                  ButtonSegment(value: WindSpeedUnit.mps, label: Text('M/S')),
                  ButtonSegment(value: WindSpeedUnit.kph, label: Text('KM/H')),
                ],
                selected: {unit},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    _controller.setSpeedUnit(set.first);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Wind Direction Slider
            _buildSliderRow(
              context,
              label:
                  'Wind Bearing: ${_controller.windDirection.toStringAsFixed(0)} deg (${resolution.compassHeadingLabel})',
              icon: Icons.air_rounded,
              value: _controller.windDirection,
              min: 0,
              max: 359,
              divisions: 72,
              onChanged: _controller.updateWindDirection,
            ),
            // Quick Cardinal Chips for Wind
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildHeadingChip(
                  'N (0 deg)',
                  0.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
                _buildHeadingChip(
                  'NE (45 deg)',
                  45.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
                _buildHeadingChip(
                  'E (90 deg)',
                  90.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
                _buildHeadingChip(
                  'S (180 deg)',
                  180.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
                _buildHeadingChip(
                  'W (270 deg)',
                  270.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
                _buildHeadingChip(
                  'NW (315 deg)',
                  315.0,
                  _controller.windDirection,
                  _controller.updateWindDirection,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Hole Heading Slider
            _buildSliderRow(
              context,
              label:
                  'Hole Heading: ${_controller.holeHeading.toStringAsFixed(0)} deg (${resolution.holeHeadingLabel})',
              icon: Icons.navigation_rounded,
              value: _controller.holeHeading,
              min: 0,
              max: 359,
              divisions: 72,
              onChanged: _controller.updateHoleHeading,
            ),
            const SizedBox(height: 14),
            // Wind Speed Slider
            _buildSliderRow(
              context,
              label:
                  'Wind Speed: ${_controller.displayWindSpeed.toStringAsFixed(1)} ${unit.label}',
              icon: Icons.speed_rounded,
              value: _controller.displayWindSpeed.clamp(0.0, 50.0),
              min: 0,
              max: 50,
              divisions: 100,
              onChanged: _controller.updateWindSpeed,
            ),
            const SizedBox(height: 14),
            // Shot Distance Slider
            _buildSliderRow(
              context,
              label:
                  'Target Shot Distance: ${_controller.shotDistanceYards.toStringAsFixed(0)} yds',
              icon: Icons.golf_course_rounded,
              value: _controller.shotDistanceYards,
              min: 40,
              max: 320,
              divisions: 56,
              onChanged: _controller.updateShotDistance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHeadingChip(
    String label,
    double targetDegree,
    double currentDegree,
    ValueChanged<double> onSelected,
  ) {
    final isSelected = (currentDegree - targetDegree).abs() < 5;
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      onPressed: () => onSelected(targetDegree),
    );
  }

  void _showHistoryModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recorded Shot Vector History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_controller.history.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          await _controller.clearHistory();
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            AppFeedback.showInfo(context, 'History cleared');
                          }
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (_controller.history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No shot vectors logged yet.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _controller.history.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _controller.history[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.sports_golf_rounded,
                              color: colorScheme.onSecondaryContainer,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            '${item.shotDistanceYards.toStringAsFixed(0)}y shot -> ${item.playAsYards.toStringAsFixed(0)}y play-as',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${item.windSpeedKnots.toStringAsFixed(0)}kts wind @ ${item.windDirection.toStringAsFixed(0)} deg | Drift ${item.lateralDriftYards.toStringAsFixed(1)}y',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
