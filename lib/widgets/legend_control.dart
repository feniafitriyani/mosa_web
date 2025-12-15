import 'package:flutter/material.dart';
import '../models/asset.dart';

class LegendControl extends StatefulWidget {
  final Set<AssetStatus> visibleStatuses;
  final Function(AssetStatus, bool) onStatusToggle;
  final Color Function(AssetStatus) getStatusColor;

  const LegendControl({
    super.key,
    required this.visibleStatuses,
    required this.onStatusToggle,
    required this.getStatusColor,
  });

  @override
  State<LegendControl> createState() => _LegendControlState();
}

class _LegendControlState extends State<LegendControl> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Legend Dropdown (positioned above button when expanded)
          if (_isExpanded)
            Container(
              width: 200,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...AssetStatus.values.map((status) {
                    final isVisible = widget.visibleStatuses.contains(status);
                    return InkWell(
                      onTap: () => widget.onStatusToggle(status, !isVisible),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color:
                                    isVisible
                                        ? widget.getStatusColor(status)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isVisible
                                          ? widget.getStatusColor(status)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isVisible
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface
                                        : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 16,
                              color:
                                  isVisible
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Legend Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Tooltip(
                  message: 'Legend',
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return 'Active';
      case AssetStatus.operating:
        return 'Operating';
      case AssetStatus.hold:
        return 'Hold';
      case AssetStatus.inactive:
        return 'Inactive';
    }
  }
}
