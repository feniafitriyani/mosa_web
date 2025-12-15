# Repository Overview

This repo is a Flutter application (Flutter Map based) located at d:\MOSA\Aplikasi Web\mosa_maps_web.

## Key Points
- Main app entry: lib/main.dart
- Primary map UI: lib/screens/maps_screen.dart
- Uses flutter_map ^8.2.1 and latlong2 ^0.9.1
- Assets folder: assets/maps/ (contains GeoTIFF Berau_3.tif and shapefiles like Berau_3_Blok.*)
- pubspec.yaml already includes assets/maps/ in flutter assets.

## Map Implementation Summary
- Base map layers are selected via LayerControl (lib/widgets/layer_control.dart)
- A local GeoTIFF (assets/maps/Berau_3.tif) is decoded via image package and rendered as OverlayImageLayer with fade-in.
- Map bounds fallback is set for the Berau area; JSON bounds can be provided at assets/maps/berau.bounds.json.
- Asset markers and filtering provided via DataService and AssetSidebarWithSearch.

## New Layer (Berau_3_Blok)
- Code expects a GeoJSON file at assets/maps/Berau_3_Blok.geojson (FeatureCollection of Polygon/MultiPolygon)
- When present, polygons render above the base map and GeoTIFF with an orange border + transparent fill.

## Run
- flutter run -d chrome (or any supported platform)

## Notes
- If Berau_3_Blok.geojson is missing, the layer is simply not displayed (no crash).
- To change polygon styling or add a toggle, adjust maps_screen.dart accordingly.