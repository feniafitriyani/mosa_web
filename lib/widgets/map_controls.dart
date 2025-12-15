import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapControls extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onResetView;
  final VoidCallback onRecenter;

  const MapControls({
    super.key,
    required this.mapController,
    required this.onResetView,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom In
        _buildControlButton(
          context: context,
          icon: Icons.add,
          tooltip: 'Zoom In',
          onPressed: () {
            final currentZoom = mapController.camera.zoom;
            mapController.move(mapController.camera.center, currentZoom + 1);
          },
        ),
        const SizedBox(height: 8),

        // Zoom Out
        _buildControlButton(
          context: context,
          icon: Icons.remove,
          tooltip: 'Zoom Out',
          onPressed: () {
            final currentZoom = mapController.camera.zoom;
            mapController.move(mapController.camera.center, currentZoom - 1);
          },
        ),
        const SizedBox(height: 8),

        // Reset Map View
        _buildControlButton(
          context: context,
          icon: Icons.refresh,
          tooltip: 'Reset Map View',
          onPressed: onResetView,
        ),
        const SizedBox(height: 8),

        // Recenter
        _buildControlButton(
          context: context,
          icon: Icons.my_location,
          tooltip: 'Recenter',
          onPressed: onRecenter,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Tooltip(
              message: tooltip,
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
