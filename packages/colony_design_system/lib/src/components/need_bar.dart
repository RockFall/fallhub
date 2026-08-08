import 'package:flutter/material.dart';

import '../chrome/colony_assets.dart';
import '../tokens/colony_tokens.dart';

class NeedBarData {
  const NeedBarData({
    required this.label,
    this.normalizedValue,
    this.targetMin,
    this.targetMax,
    this.warningThreshold,
    this.criticalThreshold,
    this.confidenceLabel,
    this.freshnessLabel,
    this.sourceSummary,
    this.statusText,
    this.higherIsBetter = true,
  });

  final String label;
  final double? normalizedValue;
  final double? targetMin;
  final double? targetMax;
  final double? warningThreshold;
  final double? criticalThreshold;
  final String? confidenceLabel;
  final String? freshnessLabel;
  final String? sourceSummary;
  final String? statusText;
  final bool higherIsBetter;
}

class NeedBar extends StatelessWidget {
  const NeedBar({super.key, required this.data});

  final NeedBarData data;

  @override
  Widget build(BuildContext context) {
    final value = data.normalizedValue;
    final barColor = _barColor(value);

    return Semantics(
      label: '${data.label}, ${data.statusText ?? _valueLabel(value)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                data.statusText ?? _valueLabel(value),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColonyColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: ColonySpacing.xs),
          SizedBox(
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColonyColors.void_,
                border: Border.all(color: ColonyColors.borderStandard),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fraction = value?.clamp(0.0, 1.0) ?? 0.0;
                  final width = constraints.maxWidth * fraction;
                  return Stack(
                    children: [
                      if (value == null)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: ColonyColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: width,
                            decoration: BoxDecoration(
                              color: barColor,
                              image: DecorationImage(
                                image: AssetImage(
                                  ColonyAssets.needsBarFill,
                                  package: ColonyAssets.package,
                                ),
                                fit: BoxFit.fill,
                                colorFilter: ColorFilter.mode(
                                  barColor,
                                  BlendMode.modulate,
                                ),
                                filterQuality: FilterQuality.none,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (data.sourceSummary != null) ...[
            const SizedBox(height: ColonySpacing.xs),
            Text(
              data.sourceSummary!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColonyColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _valueLabel(double? value) {
    if (value == null) return 'Desconhecido';
    return '${(value * 100).round()}%';
  }

  Color _barColor(double? value) {
    if (value == null) return ColonyColors.statusUnknown;
    if (data.criticalThreshold != null &&
        value <= data.criticalThreshold!) {
      return ColonyColors.statusCritical;
    }
    if (data.warningThreshold != null && value <= data.warningThreshold!) {
      return ColonyColors.statusAttention;
    }
    // Healthy needs use the vanilla cyan fill language.
    return ColonyColors.needsFill;
  }
}
