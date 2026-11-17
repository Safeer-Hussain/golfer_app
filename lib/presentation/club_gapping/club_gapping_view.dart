import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/utils/app_feedback.dart';
import 'club_gapping_controller.dart';
import 'widgets/club_gapping_table.dart';
import 'widgets/distance_dispersion_radar_card.dart';
import 'widgets/gapping_summary_cockpit_card.dart';

class ClubGappingView extends StatefulWidget {
  const ClubGappingView({super.key});

  @override
  State<ClubGappingView> createState() => _ClubGappingViewState();
}

class _ClubGappingViewState extends State<ClubGappingView> {
  late final ClubGappingController _controller;
  final ScrollController _portraitScrollController = ScrollController();
  final ScrollController _landscapeLeftController = ScrollController();
  final ScrollController _landscapeRightController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<ClubGappingController>();
  }

  @override
  void dispose() {
    _portraitScrollController.dispose();
    _landscapeLeftController.dispose();
    _landscapeRightController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Distance Gapping Guide',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A tour-level 14-club bag maintains consistent 8 to 15 yard distance steps between consecutive clubs.',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            _buildGuideRow(
              color: colorScheme.primary,
              title: 'Optimal Gap (8-15 yds)',
              desc:
                  'Predictable distance spacing for complete course coverage.',
            ),
            const SizedBox(height: 8),
            _buildGuideRow(
              color: colorScheme.error,
              title: 'Wide Gap (> 15 yds)',
              desc: 'Distance blind spot where golfer is caught between clubs.',
            ),
            const SizedBox(height: 8),
            _buildGuideRow(
              color: colorScheme.error,
              title: 'Overlap (< 8 yds)',
              desc: 'Club redundancy where two clubs travel nearly equal distance.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4, right: 8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(desc, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  void _exportReport(BuildContext context) {
    final report = _controller.report;
    if (report == null) return;

    final mode = _controller.usesCarryDistance ? 'Carry' : 'Total';
    final alertCount = report.wideGapsCount + report.overlapCount;

    AppFeedback.showSuccess(
      context,
      'Gapping Report Exported: 14 clubs analyzed ($mode). Avg gap ${report.averageGapYards}y with $alertCount flagged intervals.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final report = _controller.report;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Club Gapping & Dispersion'),
            toolbarHeight: isLandscape ? 40 : kToolbarHeight,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Gapping Guide',
                onPressed: () => _showInfoDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reset to Defaults',
                onPressed: () {
                  _controller.resetToDefaults();
                  AppFeedback.showInfo(
                    context,
                    'Reset 14-club bag to Tour default yardages.',
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_gapping_export',
            icon: const Icon(Icons.share_rounded),
            label: const Text('Export Gapping'),
            onPressed: () => _exportReport(context),
          ),
          body: report == null
              ? const SizedBox.shrink()
              : isLandscape
              ? _buildLandscapeLayout(context, report)
              : _buildPortraitLayout(context, report),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, dynamic report) {
    return SingleChildScrollView(
      controller: _portraitScrollController,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GappingSummaryCockpitCard(
            report: report,
            usesCarryDistance: _controller.usesCarryDistance,
            onToggleMetric: _controller.toggleDistanceMetric,
          ),
          const SizedBox(height: 10),
          DistanceDispersionRadarCard(
            report: report,
            selectedClub: _controller.selectedClub,
            selectedProfile: _controller.selectedClubDispersion,
            onSelectClub: _controller.selectClub,
          ),
          const SizedBox(height: 10),
          ClubGappingTable(
            report: report,
            selectedClubId: _controller.selectedClubId,
            onSelectClub: _controller.selectClub,
            onUpdateYardage: (id, carry, total) {
              _controller.updateClubYardages(id, carry, total);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, dynamic report) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Gapping Table & Summary Cockpit
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              controller: _landscapeLeftController,
              padding: const EdgeInsets.only(right: 6, bottom: 64),
              child: Column(
                children: [
                  GappingSummaryCockpitCard(
                    report: report,
                    usesCarryDistance: _controller.usesCarryDistance,
                    onToggleMetric: _controller.toggleDistanceMetric,
                  ),
                  const SizedBox(height: 8),
                  ClubGappingTable(
                    report: report,
                    selectedClubId: _controller.selectedClubId,
                    onSelectClub: _controller.selectClub,
                    onUpdateYardage: (id, carry, total) {
                      _controller.updateClubYardages(id, carry, total);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Right Pane: Dispersion Radar & Metrics
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              controller: _landscapeRightController,
              padding: const EdgeInsets.only(left: 6, bottom: 64),
              child: DistanceDispersionRadarCard(
                report: report,
                selectedClub: _controller.selectedClub,
                selectedProfile: _controller.selectedClubDispersion,
                onSelectClub: _controller.selectClub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
