import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvisioning {
  static final Guid serviceUuid =
      Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  static final Guid ssidUuid =
      Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
  static final Guid passUuid =
      Guid("beb5483e-36e1-4688-b7f5-ea07361b26a9");

  static Future<void> sendWifiCredentials({
    required BluetoothDevice device,
    required String ssid,
    required String password,
  }) async {
    final services = await device.discoverServices();

    BluetoothCharacteristic? ssidChar;
    BluetoothCharacteristic? passChar;

    for (final s in services) {
      if (s.uuid == serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid == ssidUuid) ssidChar = c;
          if (c.uuid == passUuid) passChar = c;
        }
      }
    }

    if (ssidChar == null || passChar == null) {
      throw Exception("No se encontraron características SSID/PASS");
    }

    await ssidChar.write(utf8.encode(ssid), withoutResponse: false);
    await Future.delayed(const Duration(milliseconds: 250));
    await passChar.write(utf8.encode(password), withoutResponse: false);
  }
}