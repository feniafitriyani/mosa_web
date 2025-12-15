import 'package:flutter/material.dart';
import '../models/asset.dart';
import 'search_section.dart';

class AssetSidebar extends StatefulWidget {
  final List<Asset> assets;
  final Function(Asset) onAssetTap;
  final Asset? selectedAsset;
  final double? width;
  final Function(bool)? onCollapseChanged;

  const AssetSidebar({
    super.key,
    required this.assets,
    required this.onAssetTap,
    this.selectedAsset,
    this.width,
    this.onCollapseChanged,
  });

  @override
  State<AssetSidebar> createState() => _AssetSidebarState();
}

class _AssetSidebarState extends State<AssetSidebar> {
  bool _isCollapsed = false;

  Color _getStatusColor(AssetStatus status) {
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

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    widget.onCollapseChanged?.call(_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    double sidebarWidth = widget.width ?? 350;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : sidebarWidth,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed)
                  const Expanded(
                    child: Text(
                      'Asset List',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Collapse/Expand button
                GestureDetector(
                  onTap: _toggleCollapse,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!_isCollapsed) ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.assets.length,
                itemBuilder: (context, index) {
                  final asset = widget.assets[index];
                  final isSelected = widget.selectedAsset?.id == asset.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            '${asset.site} - ${asset.block}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    asset.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _getStatusColor(asset.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  asset.statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getStatusColor(asset.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => widget.onAssetTap(asset),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: widget.assets.length,
                itemBuilder: (context, index) {
                  final asset = widget.assets[index];
                  final isSelected = widget.selectedAsset?.id == asset.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Text(
                        asset.name.split(' ').first,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onAssetTap(asset),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AssetSidebarWithSearch extends StatefulWidget {
  final List<Asset> assets;
  final Function(Asset) onAssetTap;
  final Asset? selectedAsset;
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
  final double? width;
  final Function(bool)? onCollapseChanged;

  const AssetSidebarWithSearch({
    super.key,
    required this.assets,
    required this.onAssetTap,
    this.selectedAsset,
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
    this.width,
    this.onCollapseChanged,
  });

  @override
  State<AssetSidebarWithSearch> createState() => _AssetSidebarWithSearchState();
}

class _AssetSidebarWithSearchState extends State<AssetSidebarWithSearch> {
  bool _showSearch = false;
  bool _isCollapsed = false;

  Color _getStatusColor(AssetStatus status) {
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

  // void _toggleCollapse() {
  //   setState(() {
  //     _isCollapsed = !_isCollapsed;
  //     if (_isCollapsed) {
  //       _showSearch = false;
  //     }
  //   });
  //   widget.onCollapseChanged?.call(_isCollapsed);
  // }

  @override
  Widget build(BuildContext context) {
    double sidebarWidth = widget.width ?? 350;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 80 : sidebarWidth,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed) ...[
                  const Expanded(
                    child: Text(
                      'Asset List',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = !_showSearch;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color:
                            _showSearch
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
                // GestureDetector(
                //   onTap: _toggleCollapse,
                //   child: Container(
                //     padding: const EdgeInsets.all(4),
                //     margin: const EdgeInsets.only(right: 2),
                //     decoration: BoxDecoration(
                //       color: Colors.white.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(4),
                //     ),
                //     child: Icon(
                //       _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                //       color: Colors.white,
                //       size: 18,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          if (!_isCollapsed) ...[
            if (_showSearch)
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(16),
                child: CompactSearchSection(
                  sites: widget.sites,
                  units: widget.units,
                  selectedSite: widget.selectedSite,
                  selectedEquipmentType: widget.selectedEquipmentType,
                  selectedUnit: widget.selectedUnit,
                  selectedStatus: widget.selectedStatus,
                  onSiteChanged: widget.onSiteChanged,
                  onEquipmentTypeChanged: widget.onEquipmentTypeChanged,
                  onUnitChanged: widget.onUnitChanged,
                  onStatusChanged: widget.onStatusChanged,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.assets.length,
                itemBuilder: (context, index) {
                  final asset = widget.assets[index];
                  final isSelected = widget.selectedAsset?.id == asset.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            '${asset.site} - ${asset.block}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      asset.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _getStatusColor(asset.status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    asset.statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getStatusColor(asset.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => widget.onAssetTap(asset),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: widget.assets.length,
                itemBuilder: (context, index) {
                  final asset = widget.assets[index];
                  final isSelected = widget.selectedAsset?.id == asset.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Text(
                        asset.name.split(' ').first,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onAssetTap(asset),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
