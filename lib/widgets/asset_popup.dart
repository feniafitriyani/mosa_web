import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class AssetPopup extends StatefulWidget {
  final Asset asset;
  final VoidCallback onViewDetail;
  final VoidCallback onTrack;
  final VoidCallback onClose;

  const AssetPopup({
    super.key,
    required this.asset,
    required this.onViewDetail,
    required this.onTrack,
    required this.onClose,
  });

  @override
  State<AssetPopup> createState() => _AssetPopupState();
}

class _AssetPopupState extends State<AssetPopup> {
  Offset offset = Offset.zero;
  double _width = 500.0;
  double _height = 400.0;

  Color _getStatusColor(BuildContext context, AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return Colors.green;
      case AssetStatus.operating:
        return Colors.teal;
      case AssetStatus.hold:
        return Colors.orange;
      case AssetStatus.inactive:
        return Theme.of(context).colorScheme.outline;
    }
  }

  // Build SVG icon (transparent background) with status-based color
  Widget _buildAssetSvg(Asset asset, Color color, {double size = 34}) {
    String path;
    final name = asset.name.toLowerCase();
    if (name.contains('fuel')) {
      path = 'assets/icons/fuel_truck.svg';
    } else if (name.contains('ripper')) {
      path = 'assets/icons/ripper.svg';
    } else {
      switch (asset.type) {
        case EquipmentType.excavator:
          path = 'assets/icons/excavator.svg';
          break;
        case EquipmentType.dozer:
          path = 'assets/icons/bulldozer.svg';
          break;
        case EquipmentType.hauler:
          path = 'assets/icons/dump_truck.svg';
          break;
        case EquipmentType.grader:
          path = 'assets/icons/excavator.svg';
          break;
        case EquipmentType.fuel:
          path = 'assets/icons/fuel_truck.svg';
          break;
      }
    }
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  ButtonStyle _buildPrimaryActionStyle(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color baseColor = colorScheme.primary;
    final Color hoverColor = Color.lerp(baseColor, Colors.black, 0.12)!;
    final Color pressedColor = Color.lerp(baseColor, Colors.black, 0.24)!;

    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      foregroundColor: colorScheme.onPrimary,
    ).copyWith(
      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return pressedColor;
        }
        if (states.contains(MaterialState.hovered) ||
            states.contains(MaterialState.focused)) {
          return hoverColor;
        }
        return baseColor;
      }),
    );
  }

  void _handleClose() {
    setState(() {
      offset = Offset.zero;
    });
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _getStatusColor(context, widget.asset.status);
    return Transform.translate(
      offset: offset,
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (_) {
              FocusScope.of(context).unfocus();
            },
            onPanUpdate: (details) {
              setState(() {
                offset += details.delta;
              });
            },
            child: SizedBox(
              width: _width,
              height: _height,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Transparent background, SVG colored by status
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: _buildAssetSvg(
                                    widget.asset,
                                    iconColor,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.asset.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _handleClose,
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Asset Information
                      _buildInfoRow('Type', widget.asset.typeText),
                      _buildInfoRow(
                        'Status',
                        widget.asset.statusText,
                        statusColor: _getStatusColor(
                          context,
                          widget.asset.status,
                        ),
                      ),
                      _buildInfoRow('Site', widget.asset.site),
                      _buildInfoRow('Block', widget.asset.block),
                      _buildInfoRow('Pit', widget.asset.pit),
                      if (widget.asset.operator != null)
                        _buildInfoRow('Operator', widget.asset.operator!),
                      _buildInfoRow(
                        'Last Updated',
                        DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(widget.asset.lastUpdated),
                      ),
                      _buildInfoRow(
                        'Coordinates',
                        '${widget.asset.position.latitude.toStringAsFixed(6)}, '
                            '${widget.asset.position.longitude.toStringAsFixed(6)}',
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.onViewDetail,
                              style: _buildPrimaryActionStyle(context),
                              child: const Text(
                                'View Detail',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.onTrack,
                              style: _buildPrimaryActionStyle(context),
                              child: const Text(
                                'Track',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _width = max(300.0, _width + details.delta.dx);
                  _height = max(200.0, _height + details.delta.dy);
                });
              },
              child: Container(
                width: 20,
                height: 20,
                color: Colors.transparent,
                child: const Icon(Icons.aspect_ratio, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child:
                statusColor != null
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
