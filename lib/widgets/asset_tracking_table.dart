import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../services/data_service.dart';

/// Widget that displays tracking points for a given [asset] and allows
/// filtering by start and end dates.
class AssetTrackingTable extends StatefulWidget {
  final Asset asset;
  final VoidCallback onClose;
  final ValueChanged<List<AssetTrackingPoint>>? onFilteredPointsChanged;

  const AssetTrackingTable({
    super.key,
    required this.asset,
    required this.onClose,
    this.onFilteredPointsChanged,
  });

  @override
  State<AssetTrackingTable> createState() => _AssetTrackingTableState();
}

class _AssetTrackingTableState extends State<AssetTrackingTable> {
  DateTime? _startDate;
  DateTime? _endDate;
  late List<AssetTrackingPoint> _trackingData;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Default to last 7 days
    _startDate = DateTime.now().subtract(const Duration(days: 7));
    _endDate = DateTime.now();
    _loadTrackingData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadTrackingData() {
    final data = DataService.getTrackingDataFiltered(
        widget.asset.id,
        startDate: _startDate,
        endDate: _endDate,
      )
      // Pastikan urutan mengikuti kronologi waktu
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    setState(() {
      _trackingData = data;
    });
    widget.onFilteredPointsChanged?.call(data);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStartDate) {
        _startDate = selectedDateTime;
      } else {
        _endDate = selectedDateTime;
      }
      _loadTrackingData();
    });
  }

  Color _getStatusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.active:
        return Colors.green;
      case AssetStatus.operating:
        return Colors.teal;
      case AssetStatus.hold:
        return Colors.orange;
      case AssetStatus.inactive:
        return Colors.grey;
    }
  }

  Widget _buildAssetSvg(Asset asset, Color color, {double size = 32}) {
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

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
    return Container(
      color: Colors.grey[50],
      constraints: const BoxConstraints(minHeight: 250.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asset Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAssetSvg(
                            widget.asset,
                            _getStatusColor(widget.asset.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.asset.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                widget.asset.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getStatusColor(widget.asset.status),
                              ),
                            ),
                            child: Text(
                              widget.asset.statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(widget.asset.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Date Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                final double fieldWidth =
                    isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _DateField(
                        label: 'Start Time',
                        dateTime: _startDate,
                        onTap: () => _selectDate(context, true),
                        dateFormatter: dateFormatter,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _DateField(
                        label: 'End Time',
                        dateTime: _endDate,
                        onTap: () => _selectDate(context, false),
                        dateFormatter: dateFormatter,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Table content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Header Row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: const Border(
                        bottom: BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey.shade300),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.5), // Date
                        1: FlexColumnWidth(1.5), // Position
                        2: FlexColumnWidth(1), // Status
                      },
                      children: const [
                        TableRow(
                          children: [
                            _TableCell('Date', isHeader: true),
                            _TableCell('Position', isHeader: true),
                            _TableCell('Status', isHeader: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Scrollable rows
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.vertical,
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: Colors.grey.shade300),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(1.5),
                            2: FlexColumnWidth(1),
                          },
                          children: [
                            ..._trackingData.map(
                              (point) => TableRow(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                children: [
                                  _TableCell(
                                    DateFormat(
                                      'yyyy-MM-dd HH:mm',
                                    ).format(point.timestamp),
                                  ),
                                  _TableCell(
                                    '${point.position.latitude.toStringAsFixed(6)}, '
                                    '${point.position.longitude.toStringAsFixed(6)}',
                                  ),
                                  _TableCell(point.status),
                                ],
                              ),
                            ),
                            if (_trackingData.isEmpty)
                              const TableRow(
                                children: [
                                  _TableCell('No tracking data available'),
                                  _TableCell(''),
                                  _TableCell(''),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple table cell widget used by both tables
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color:
              isHeader
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

// Re‑usable date field widget (same as in task history)
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;
  final DateFormat dateFormatter;

  const _DateField({
    required this.label,
    required this.dateTime,
    required this.onTap,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateTime != null
                        ? dateFormatter.format(dateTime!)
                        : 'Select date',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
