import 'package:flutter/material.dart';
import 'nasa_date_picker.dart';

class LayerControl extends StatefulWidget {
  final String currentLayer;
  final Function(String) onLayerChanged;
  final DateTime nasaDate;
  final Function(DateTime) onNasaDateChanged;

  const LayerControl({
    super.key,
    required this.currentLayer,
    required this.onLayerChanged,
    required this.nasaDate,
    required this.onNasaDateChanged,
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
    // Open map choices
    'wikimedia': 'Open Map - Wikimedia',
    'carto-light': 'Open Map - Carto Light',
    // Satellite choices
    'usgs-satellite': 'Satellite - USGS Imagery',
    'esa-sentinel-2-true-color': 'Satellite - Sentinel-2 True Color',
  };

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
                        maxHeight: 180, // Responsive max height
                        minHeight: 100,
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children:
                                _layers.entries.map((entry) {
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
