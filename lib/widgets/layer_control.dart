import 'package:flutter/material.dart';
import 'nasa_date_picker.dart';

class LayerControl extends StatefulWidget {
  final String currentLayer;
  final Function(String) onLayerChanged;
  final DateTime nasaDate;
  final Function(DateTime) onNasaDateChanged;

  // Overlay toggles
  final bool showBlockStrip;
  final ValueChanged<bool> onShowBlockStripChanged;
  // Layer Sarijadi
  // (assets/maps/Sarijadi_Blocks.json, Sarijadi_Area.json,
  //  Sarijadi_Blocks_Strips.json)
  final bool showSarijadiBlocks;
  final ValueChanged<bool> onShowSarijadiBlocksChanged;
  final bool showSarijadiArea;
  final ValueChanged<bool> onShowSarijadiAreaChanged;
  // assets/maps/Sarijadi_Points.json (titik corner + titik PIT)
  final bool showSarijadiPoints;
  final ValueChanged<bool> onShowSarijadiPointsChanged;
  final bool showCornerPoints;
  final ValueChanged<bool> onShowCornerPointsChanged;
  final bool showSarijadiLabels;
  final ValueChanged<bool> onShowSarijadiLabelsChanged;

  const LayerControl({
    super.key,
    required this.currentLayer,
    required this.onLayerChanged,
    required this.nasaDate,
    required this.onNasaDateChanged,
    required this.showBlockStrip,
    required this.onShowBlockStripChanged,
    required this.showSarijadiBlocks,
    required this.onShowSarijadiBlocksChanged,
    required this.showSarijadiArea,
    required this.onShowSarijadiAreaChanged,
    required this.showSarijadiPoints,
    required this.onShowSarijadiPointsChanged,
    required this.showCornerPoints,
    required this.onShowCornerPointsChanged,
    required this.showSarijadiLabels,
    required this.onShowSarijadiLabelsChanged,
  });

  @override
  State<LayerControl> createState() => _LayerControlState();
}

class _LayerControlState extends State<LayerControl> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isNasaLayer(String layer) {
    return false; // Tidak ada layer NASA saat ini
  }

  final Map<String, String> _layers = {
    'geotiff-base': 'GeoTIFF (Berau)',
    // Open map choices (tile dari OpenStreetMap & turunannya)
    'osm': 'Open Map - OpenStreetMap',
    'carto-light': 'Open Map - Carto Light',
    'wikimedia': 'Open Map - Wikimedia',
    // // Satellite choices
    // 'usgs-satellite': 'Satellite - USGS Imagery',
    // 'esa-sentinel-2-true-color': 'Satellite - Sentinel-2 True Color',
  };

  Widget _buildOverlayToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? filename,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (filename != null)
                    Text(
                      filename,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          // Layer Button
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
                  message: 'Map Layers',
                  child: Icon(
                    Icons.layers,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),

          // Layer Dropdown
          if (_isExpanded)
            Container(
              width: 280,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                maxHeight: 400, // Limit maximum height
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Map Layers',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 250, // Increased to accommodate overlays
                        minHeight: 100,
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._layers.entries.map((entry) {
                                final isSelected =
                                    widget.currentLayer == entry.key;
                                return InkWell(
                                  onTap: () {
                                    widget.onLayerChanged(entry.key);
                                    setState(() {
                                      _isExpanded = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          size: 16,
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                  : Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              const Divider(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Overlays',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              _buildOverlayToggle(
                                label: 'Sarijadi Blocks',
                                value: widget.showSarijadiBlocks,
                                onChanged: widget.onShowSarijadiBlocksChanged,
                                filename: 'Sarijadi_Blocks.json',
                              ),
                              _buildOverlayToggle(
                                label: 'Sarijadi Area',
                                value: widget.showSarijadiArea,
                                onChanged: widget.onShowSarijadiAreaChanged,
                                filename: 'Sarijadi_Area.json',
                              ),
                              _buildOverlayToggle(
                                label: 'Block Strip',
                                value: widget.showBlockStrip,
                                onChanged: widget.onShowBlockStripChanged,
                                filename: 'Sarijadi_Blocks_Strips.json',
                              ),
                              _buildOverlayToggle(
                                label: 'Sarijadi Points',
                                value: widget.showSarijadiPoints,
                                onChanged: widget.onShowSarijadiPointsChanged,
                                filename: 'Sarijadi_Points.json',
                              ),
                              if (widget.showSarijadiPoints)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24),
                                  child: _buildOverlayToggle(
                                    label: 'Corner Points',
                                    value: widget.showCornerPoints,
                                    onChanged: widget.onShowCornerPointsChanged,
                                  ),
                                ),
                              if (widget.showSarijadiBlocks ||
                                  widget.showSarijadiArea ||
                                  widget.showBlockStrip ||
                                  widget.showSarijadiPoints)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24),
                                  child: _buildOverlayToggle(
                                    label: 'Sarijadi Labels',
                                    value: widget.showSarijadiLabels,
                                    onChanged:
                                        widget.onShowSarijadiLabelsChanged,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // NASA Date Picker
                  NasaDatePicker(
                    selectedDate: widget.nasaDate,
                    onDateChanged: widget.onNasaDateChanged,
                    isVisible: _isNasaLayer(widget.currentLayer),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
