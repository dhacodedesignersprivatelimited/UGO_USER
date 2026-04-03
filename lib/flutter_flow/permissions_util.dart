import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '/flutter_flow/flutter_flow_util.dart';

const kPermissionStateToBool = {
  PermissionStatus.granted: true,
  PermissionStatus.limited: true,
  PermissionStatus.denied: false,
  PermissionStatus.restricted: false,
  PermissionStatus.permanentlyDenied: false,
};

final locationPermission = Permission.location;
final notificationsPermission = Permission.notification;

Future<bool> getPermissionStatus(Permission setting) async {
  final status = await setting.status;
  return kPermissionStateToBool[status]!;
}

/// Requests only when needed — avoids re-showing the system sheet if already granted.
Future<void> requestPermission(Permission setting) async {
  if (setting == Permission.photos && isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final p = androidInfo.version.sdkInt <= 32
        ? Permission.storage
        : Permission.photos;
    final st = await p.status;
    if (st.isGranted || st.isLimited) return;
    if (st.isPermanentlyDenied) return;
    await p.request();
    return;
  }

  final status = await setting.status;
  if (status.isGranted || status.isLimited) return;
  if (status.isPermanentlyDenied) return;
  await setting.request();
}
