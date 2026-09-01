import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../tasks/presentation/task_state.dart';
import '../../user/domain/user_profile.dart';
import '../../user/presentation/user_state.dart';
import '../domain/location_models.dart';
import 'location_state.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  Timer? _mapDebounce;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<UserState>().profile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LocationState>().initialize(
        communityName: profile?.communityName,
        buildingName: profile?.buildingName,
      );
    });
  }

  @override
  void dispose() {
    _mapDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LocationState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('所在位置'),
        actions: [
          IconButton(
            tooltip: '定位到当前位置',
            onPressed: state.isLocating ? null : _locate,
            icon: state.isLocating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final map = _MapArea(
            controller: _mapController,
            state: state,
            onMapSettled: _scheduleMapRefresh,
            onCommunityTap: _selectCommunity,
          );
          final selector = _LocationSelector(
            state: state,
            onCommunityTap: _selectCommunity,
            onBuildingTap: _selectBuilding,
            onConfirm: _confirm,
          );
          if (isWide) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(flex: 5, child: map),
                  const SizedBox(width: 16),
                  SizedBox(width: 360, child: selector),
                ],
              ),
            );
          }
          return Column(
            children: [
              SizedBox(height: constraints.maxHeight * .46, child: map),
              Expanded(child: selector),
            ],
          );
        },
      ),
    );
  }

  void _scheduleMapRefresh(LatLng point) {
    _mapDebounce?.cancel();
    _mapDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      context.read<LocationState>().loadCommunities(
        latitude: point.latitude,
        longitude: point.longitude,
      );
    });
  }

  Future<void> _locate() async {
    final state = context.read<LocationState>();
    final found = await state.locateDevice();
    if (!mounted) return;
    if (found) {
      _mapController.move(LatLng(state.latitude, state.longitude), 17);
    } else if (state.errorMessage != null) {
      _showMessage(state.errorMessage!);
    }
  }

  Future<void> _selectCommunity(CommunityPlace community) async {
    await context.read<LocationState>().selectCommunity(community);
    if (!mounted) return;
    _mapController.move(LatLng(community.latitude, community.longitude), 17);
  }

  void _selectBuilding(CommunityBuilding building) {
    context.read<LocationState>().selectBuilding(building);
    _mapController.move(LatLng(building.latitude, building.longitude), 18);
  }

  Future<void> _confirm() async {
    final location = context.read<LocationState>();
    final community = location.selectedCommunity;
    final building = location.selectedBuilding;
    if (community == null || building == null) {
      _showMessage('请选择社区和楼栋');
      return;
    }
    final success = await context.read<UserState>().updateSettings(
      UserSettingsPayload(
        communityId: community.id,
        buildingId: building.id,
        latitude: building.latitude,
        longitude: building.longitude,
      ),
    );
    if (!mounted) return;
    if (!success) {
      _showMessage(context.read<UserState>().errorMessage ?? '位置保存失败');
      return;
    }
    await context.read<AppSettings>().saveLocation(
      latitude: building.latitude,
      longitude: building.longitude,
    );
    if (!mounted) return;
    await context.read<TaskState>().refreshNearby();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MapArea extends StatelessWidget {
  const _MapArea({
    required this.controller,
    required this.state,
    required this.onMapSettled,
    required this.onCommunityTap,
  });

  final MapController controller;
  final LocationState state;
  final ValueChanged<LatLng> onMapSettled;
  final ValueChanged<CommunityPlace> onCommunityTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: BauhausColors.ink, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: LatLng(state.latitude, state.longitude),
          initialZoom: 16.5,
          minZoom: 4,
          maxZoom: 19,
          onTap: (_, point) => onMapSettled(point),
          onPositionChanged: (camera, hasGesture) {
            if (hasGesture) onMapSettled(camera.center);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.community.micro_logistics.frontend',
          ),
          MarkerLayer(
            markers: [
              for (final community in state.communities)
                Marker(
                  point: LatLng(community.latitude, community.longitude),
                  width: 54,
                  height: 62,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => onCommunityTap(community),
                    child: _MapPin(
                      selected: state.selectedCommunity?.id == community.id,
                    ),
                  ),
                ),
            ],
          ),
          RichAttributionWidget(
            attributions: const [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.12 : .9,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? BauhausColors.coral : BauhausColors.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: BauhausColors.ink, width: 3),
            ),
            child: const Icon(Icons.apartment_rounded, size: 21),
          ),
          Positioned(
            top: 38,
            child: Transform.rotate(
              angle: .78,
              child: Container(width: 12, height: 12, color: BauhausColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({
    required this.state,
    required this.onCommunityTap,
    required this.onBuildingTap,
    required this.onConfirm,
  });

  final LocationState state;
  final ValueChanged<CommunityPlace> onCommunityTap;
  final ValueChanged<CommunityBuilding> onBuildingTap;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? BauhausColors.darkPanel : BauhausColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            color: BauhausColors.cobalt,
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.selectedCommunity?.name ?? '选择社区',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                if (state.isLoading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text('附近社区', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final community in state.communities)
                      ChoiceChip(
                        label: Text(_communityLabel(community)),
                        selected: state.selectedCommunity?.id == community.id,
                        onSelected: (_) => onCommunityTap(community),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('楼栋', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (state.buildings.isEmpty && !state.isLoading)
                  Text('暂无楼栋数据', style: Theme.of(context).textTheme.bodySmall)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final building in state.buildings)
                        ChoiceChip(
                          avatar: const Icon(Icons.apartment_rounded, size: 17),
                          label: Text(building.name),
                          selected: state.selectedBuilding?.id == building.id,
                          onSelected: (_) => onBuildingTap(building),
                        ),
                    ],
                  ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: BauhausColors.coral),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: FilledButton.icon(
              onPressed: state.selectedBuilding == null ? null : onConfirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('使用这个位置'),
            ),
          ),
        ],
      ),
    );
  }

  String _communityLabel(CommunityPlace community) {
    final distance = community.distanceMeters;
    if (distance == null) return community.name;
    final label = distance < 1000
        ? '${distance.round()}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';
    return '${community.name}  $label';
  }
}
