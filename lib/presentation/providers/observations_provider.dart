import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../config/constants.dart';
import '../../domain/models/models.dart';
import 'auth_provider.dart';

/// Provider principal (MISMO NOMBRE), ahora es AsyncValue para producción
final observationProvider =
    StateNotifierProvider<ObservationNotifier, AsyncValue<List<Observation>>>((ref) {
  return ObservationNotifier(ref);
});

class ObservationNotifier extends StateNotifier<AsyncValue<List<Observation>>> {
  final Ref ref;

  ObservationNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadObservations();
  }

  /// Carga inicial (producción)
  Future<void> loadObservations() async {
    state = const AsyncValue.loading();
    try {
      final token = await ref.read(authProvider.notifier).getIdToken();
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de autenticación. Inicia sesión de nuevo.');
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/observations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        throw Exception('GET /observations failed: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final items = (decoded['observations'] ?? []) as List<dynamic>;

      final observations = items
          .map((e) => _fromApi(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(observations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refrescar (lo usa Gallery)
  Future<void> refreshObservations(String _userIdIgnored) async {
    // En producción NO necesitamos userId aquí porque el backend debe sacar el user desde Cognito.
    await loadObservations();
  }

  Observation _fromApi(Map<String, dynamic> json) {
    final id = (json['observationId'] ?? json['id'] ?? '').toString();
    final deviceId = (json['deviceId'] ?? '').toString();
    final userId = (json['userId'] ?? '').toString();

    final imageUrl = (json['imageUrl'] ?? '').toString();
    final thumbnailUrl = (json['thumbnailUrl'] ?? json['imageUrl'] ?? '').toString();

    final capturedAtRaw = (json['timestamp'] ?? json['createdAt'] ?? '').toString();
    final capturedAt = DateTime.tryParse(capturedAtRaw) ?? DateTime.now();

    final pos = (json['position'] as Map?)?.cast<String, dynamic>();
    final meta = (json['metadata'] as Map?)?.cast<String, dynamic>();

    return Observation(
      id: id,
      deviceId: deviceId,
      userId: userId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      capturedAt: capturedAt,
      position: DevicePosition(
        rightAscension: (pos?['ra'] ?? '00h 00m 00s').toString(),
        declination: (pos?['dec'] ?? '+00° 00\' 00"').toString(),
        altitude: (pos?['altitude'] as num?)?.toDouble(),
        azimuth: (pos?['azimuth'] as num?)?.toDouble(),
      ),
      metadata: meta == null
          ? null
          : ObservationMetadata(
              exposureTime: (meta['exposureTime'] as num?)?.toDouble(),
              iso: meta['iso'],
              filter: meta['filter'],
              temperature: (meta['temperature'] as num?)?.toDouble(),
            ),
    );
  }
}

/// Provider derivado: observación por ID
final observationByIdProvider = Provider.family<Observation?, String>((ref, observationId) {
  final observationsState = ref.watch(observationProvider);

  return observationsState.maybeWhen(
    data: (list) {
      try {
        return list.firstWhere((o) => o.id == observationId);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});