import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../progression/summon.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import 'rarity_stars.dart';

/// Gacha-style reveal for a batch of [SummonResult]s. Cards are revealed one at
/// a time in ascending rarity (suspense builds toward the best pull); tapping
/// advances, and a skip jumps straight to the summary grid.
class SummonRevealDialog extends StatefulWidget {
  const SummonRevealDialog({required this.results, super.key});

  final List<SummonResult> results;

  @override
  State<SummonRevealDialog> createState() => _SummonRevealDialogState();
}

class _SummonRevealDialogState extends State<SummonRevealDialog>
    with SingleTickerProviderStateMixin {
  late final List<SummonResult> _order;
  late final AnimationController _controller;
  late final Animation<double> _scale;
  int _index = 0;
  bool _summary = false;

  @override
  void initState() {
    super.initState();
    // Reveal worst → best so the run climaxes on the rarest pull.
    _order = [...widget.results]
      ..sort((a, b) => a.rarity.stars.compareTo(b.rarity.stars));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _order.length - 1) {
      setState(() => _index++);
      _controller.forward(from: 0);
    } else {
      setState(() => _summary = true);
    }
  }

  String _tag(SummonResult result) {
    if (result.isNew) return context.tr(K.summonNew);
    if (result.xpGained > 0) {
      return context.tr(K.summonDuplicate, [result.xpGained]);
    }
    return context.tr(K.summonDuplicateMaxed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.cardPadding),
        child: SizedBox(
          width: AppLayout.dialogWidth(context, 380),
          child: _summary ? _buildSummary(context) : _buildReveal(context),
        ),
      ),
    );
  }

  Widget _buildReveal(BuildContext context) {
    final result = _order[_index];
    final color = AppColors.creatureRarity(result.rarity);
    return GestureDetector(
      onTap: _next,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _summary = true),
              child: Text('${_index + 1}/${_order.length}'),
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _controller,
              child: _card(context, result, color),
            ),
          ),
          const SizedBox(height: AppLayout.sectionGap),
          Text(
            context.tr(K.summonTapToContinue),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppLayout.tinyGap),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SummonResult result, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppLayout.borderRadius),
        border: Border.all(color: color, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: .04)],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .5), blurRadius: 18),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RarityStars(rarity: result.rarity, size: 22),
          const SizedBox(height: AppLayout.controlGap),
          Text(
            context.l10n.creatureName(result.creatureId),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: AppLayout.tinyGap),
          Text(
            _tag(result),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: result.isNew ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final sorted = [...widget.results]
      ..sort((a, b) => b.rarity.stars.compareTo(a.rarity.stars));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(K.summonResultsTitle),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppLayout.controlGap),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sorted.map((result) => _summaryRow(context, result)).toList(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr(K.close)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, SummonResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.tinyGap),
      child: Row(
        children: [
          RarityStars(rarity: result.rarity, size: 12),
          const SizedBox(width: AppLayout.compactGap),
          Expanded(
            child: Text(
              context.l10n.creatureName(result.creatureId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.creatureRarity(result.rarity),
                fontWeight: result.isNew ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(_tag(result), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
