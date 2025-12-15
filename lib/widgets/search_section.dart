import 'package:flutter/material.dart';
import '../models/asset.dart';

class SearchSection extends StatefulWidget {
  final List<String> sites;
  final List<String> units;
  final String? selectedSite;
  final EquipmentType? selectedEquipmentType;
  final String? selectedUnit;
  final AssetStatus? selectedStatus;
  final Function(String?) onSiteChanged;
  final Function(EquipmentType?) onEquipmentTypeChanged;
  final Function(String?) onUnitChanged;
  final Function(AssetStatus?) onStatusChanged;

  const SearchSection({
    super.key,
    required this.sites,
    required this.units,
    this.selectedSite,
    this.selectedEquipmentType,
    this.selectedUnit,
    this.selectedStatus,
    required this.onSiteChanged,
    required this.onEquipmentTypeChanged,
    required this.onUnitChanged,
    required this.onStatusChanged,
  });

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Header - Always visible
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Search Unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const SizedBox(height: 16),

            // Site Dropdown
            Row(
              children: [
                const Icon(Icons.location_city, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Site',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    value: widget.selectedSite,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Sites',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...widget.sites.map(
                        (site) => DropdownMenuItem(
                          value: site,
                          child: Text(site, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: widget.onSiteChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Equipment Type Dropdown
            Row(
              children: [
                const Icon(Icons.construction, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<EquipmentType>(
                    decoration: const InputDecoration(
                      labelText: 'Equipment Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    value: widget.selectedEquipmentType,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...EquipmentType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getEquipmentTypeText(type)),
                        ),
                      ),
                    ],
                    onChanged: widget.onEquipmentTypeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Unit Dropdown
            Row(
              children: [
                const Icon(
                  Icons.precision_manufacturing,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    value: widget.selectedUnit,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Units',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...widget.units.map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: widget.onUnitChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Dropdown
            Row(
              children: [
                const Icon(Icons.circle, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<AssetStatus>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    value: widget.selectedStatus,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...AssetStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusText(status)),
                        ),
                      ),
                    ],
                    onChanged: widget.onStatusChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getEquipmentTypeText(EquipmentType type) {
    switch (type) {
      case EquipmentType.hauler:
        return 'Hauler';
      case EquipmentType.excavator:
        return 'Excavator';
      case EquipmentType.dozer:
        return 'Dozer';
      case EquipmentType.grader:
        return 'Grader';
      case EquipmentType.fuel:
        return 'Fuel';
    }
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

class CompactSearchSection extends StatelessWidget {
  final List<String> sites;
  final List<String> units;
  final String? selectedSite;
  final EquipmentType? selectedEquipmentType;
  final String? selectedUnit;
  final AssetStatus? selectedStatus;
  final Function(String?) onSiteChanged;
  final Function(EquipmentType?) onEquipmentTypeChanged;
  final Function(String?) onUnitChanged;
  final Function(AssetStatus?) onStatusChanged;

  const CompactSearchSection({
    super.key,
    required this.sites,
    required this.units,
    this.selectedSite,
    this.selectedEquipmentType,
    this.selectedUnit,
    this.selectedStatus,
    required this.onSiteChanged,
    required this.onEquipmentTypeChanged,
    required this.onUnitChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Site Dropdown
          Row(
            children: [
              const Icon(Icons.location_city, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Site',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  value: selectedSite,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Sites', overflow: TextOverflow.ellipsis),
                    ),
                    ...sites.map(
                      (site) => DropdownMenuItem(
                        value: site,
                        child: Text(site, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onSiteChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Equipment Type Dropdown
          Row(
            children: [
              const Icon(Icons.construction, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<EquipmentType>(
                  decoration: const InputDecoration(
                    labelText: 'Equipment Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  value: selectedEquipmentType,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...EquipmentType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getEquipmentTypeText(type)),
                      ),
                    ),
                  ],
                  onChanged: onEquipmentTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Unit Dropdown
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  value: selectedUnit,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Units', overflow: TextOverflow.ellipsis),
                    ),
                    ...units.map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onUnitChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Dropdown
          Row(
            children: [
              const Icon(Icons.circle, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<AssetStatus>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  value: selectedStatus,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...AssetStatus.values.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEquipmentTypeText(EquipmentType type) {
    switch (type) {
      case EquipmentType.hauler:
        return 'Hauler';
      case EquipmentType.excavator:
        return 'Excavator';
      case EquipmentType.dozer:
        return 'Dozer';
      case EquipmentType.grader:
        return 'Grader';
      case EquipmentType.fuel:
        return 'Fuel';
    }
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
