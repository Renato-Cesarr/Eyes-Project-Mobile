import 'dart:math' as math;

import 'package:eyes_mobile/features/object_detection/domain/detected_object.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_models.dart';
import 'package:eyes_mobile/features/proximity/domain/proximity_policy.dart';

/// Stateful, deterministic temporal engine. Time comes exclusively from the
/// captured frame, so replaying the same sequence produces the same alerts.
final class ProximityEngine {
  ProximityEngine({ProximityPolicy? policy})
    : policy = policy ?? ProximityPolicy();

  final ProximityPolicy policy;

  final Map<int, _TrackedObject> _tracks = {};
  final Map<(DetectedObjectKind, ProximityBand), DateTime>
  _lastAlertByKindAndBand = {};
  final List<ProximityAlertEvent> _eventHistory = [];
  int _nextTrackId = 1;
  DateTime? _lastCapturedAt;
  ProximityAlertEvent? _lastAlert;

  List<ProximityAlertEvent> get eventHistory =>
      List<ProximityAlertEvent>.unmodifiable(_eventHistory);

  ProximityEvaluation process(DetectionBatch batch) {
    final previousTimestamp = _lastCapturedAt;
    if (previousTimestamp != null &&
        batch.capturedAt.isBefore(previousTimestamp)) {
      throw ArgumentError.value(
        batch.capturedAt,
        'capturedAt',
        'deve ser monotônico durante a sessão',
      );
    }
    _lastCapturedAt = batch.capturedAt;

    final matches = _associate(batch.detections);
    final matchedTrackIds = <int>{};
    final matchedDetectionIndexes = <int>{};
    final visibleTracks = <_TrackedObject>[];

    for (final match in matches) {
      final track = _tracks[match.trackId]!;
      track.update(
        batch.detections[match.detectionIndex],
        batch.capturedAt,
        policy,
      );
      matchedTrackIds.add(match.trackId);
      matchedDetectionIndexes.add(match.detectionIndex);
      visibleTracks.add(track);
    }

    for (final track in _tracks.values) {
      if (!matchedTrackIds.contains(track.id)) {
        track.missedFrames++;
      }
    }
    _tracks.removeWhere(
      (int id, _TrackedObject track) =>
          track.missedFrames > policy.maximumMissedFrames,
    );

    for (var index = 0; index < batch.detections.length; index++) {
      if (matchedDetectionIndexes.contains(index)) {
        continue;
      }
      final track = _TrackedObject.create(
        id: _nextTrackId++,
        detection: batch.detections[index],
        capturedAt: batch.capturedAt,
        policy: policy,
      );
      _tracks[track.id] = track;
      visibleTracks.add(track);
    }

    visibleTracks.sort(
      (_TrackedObject a, _TrackedObject b) => a.id.compareTo(b.id),
    );
    final observations = visibleTracks
        .map(_toObservation)
        .toList(growable: false);
    final event = _selectAlert(visibleTracks, batch.capturedAt);
    if (event != null) {
      _record(event);
    }

    return ProximityEvaluation(
      observations: observations,
      capturedAt: batch.capturedAt,
      announcedEvent: event,
    );
  }

  void reset() {
    _tracks.clear();
    _lastAlertByKindAndBand.clear();
    _eventHistory.clear();
    _nextTrackId = 1;
    _lastCapturedAt = null;
    _lastAlert = null;
  }

  List<_Association> _associate(List<DetectedObject> detections) {
    final candidates = <_Association>[];
    for (final track in _tracks.values) {
      for (var index = 0; index < detections.length; index++) {
        final detection = detections[index];
        if (detection.kind != track.kind) {
          continue;
        }
        final overlap = _intersectionOverUnion(
          track.boundingBox,
          detection.boundingBox,
        );
        if (overlap >= policy.iouThreshold) {
          candidates.add(
            _Association(
              trackId: track.id,
              detectionIndex: index,
              overlap: overlap,
            ),
          );
        }
      }
    }
    candidates.sort((_Association a, _Association b) {
      final byOverlap = b.overlap.compareTo(a.overlap);
      if (byOverlap != 0) {
        return byOverlap;
      }
      final byTrack = a.trackId.compareTo(b.trackId);
      return byTrack != 0
          ? byTrack
          : a.detectionIndex.compareTo(b.detectionIndex);
    });

    final assignedTracks = <int>{};
    final assignedDetections = <int>{};
    return candidates
        .where((_Association candidate) {
          if (assignedTracks.contains(candidate.trackId) ||
              assignedDetections.contains(candidate.detectionIndex)) {
            return false;
          }
          assignedTracks.add(candidate.trackId);
          assignedDetections.add(candidate.detectionIndex);
          return true;
        })
        .toList(growable: false);
  }

  ProximityObservation _toObservation(_TrackedObject track) {
    return ProximityObservation(
      trackId: track.id,
      kind: track.kind,
      band: track.stableBand,
      direction: _direction(track.boundingBox),
      score: track.smoothedScore,
      centrality: _centrality(track.boundingBox),
      persistenceFrames: track.seenFrames,
      boundingBox: track.boundingBox,
    );
  }

  ProximityAlertEvent? _selectAlert(
    List<_TrackedObject> visibleTracks,
    DateTime capturedAt,
  ) {
    final candidates = visibleTracks
        .where((_TrackedObject track) {
          if (track.seenFrames < policy.minimumTrackFrames ||
              track.stableBand == ProximityBand.distant ||
              (!policy.announceAttention &&
                  track.stableBand == ProximityBand.attention)) {
            return false;
          }
          final lastSame =
              _lastAlertByKindAndBand[(track.kind, track.stableBand)];
          final upgraded =
              track.lastAlertBand != null &&
              track.stableBand.index > track.lastAlertBand!.index;
          if (!upgraded &&
              track.lastAlertAt != null &&
              capturedAt.difference(track.lastAlertAt!) <
                  policy.sameAlertCooldown) {
            return false;
          }
          return lastSame == null ||
              capturedAt.difference(lastSame) >= policy.sameAlertCooldown;
        })
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((_TrackedObject a, _TrackedObject b) {
      final byPriority = _priority(b).compareTo(_priority(a));
      return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
    });
    final selected = candidates.first;
    final previous = _lastAlert;
    final preemptsInformational =
        selected.stableBand == ProximityBand.veryNear &&
        previous?.band == ProximityBand.attention;
    if (!preemptsInformational &&
        previous != null &&
        capturedAt.difference(previous.occurredAt) <
            policy.globalMinimumInterval) {
      return null;
    }

    final event = ProximityAlertEvent(
      trackId: selected.id,
      kind: selected.kind,
      band: selected.stableBand,
      direction: _direction(selected.boundingBox),
      score: selected.smoothedScore,
      priority: _priority(selected),
      occurredAt: capturedAt,
    );
    selected
      ..lastAlertAt = capturedAt
      ..lastAlertBand = selected.stableBand;
    return event;
  }

  ProximityDirection _direction(NormalizedBoundingBox box) {
    final center = (box.left + box.right) / 2;
    if (center < 0.38) {
      return ProximityDirection.left;
    }
    if (center > 0.62) {
      return ProximityDirection.right;
    }
    return ProximityDirection.ahead;
  }

  double _priority(_TrackedObject track) {
    final bandWeight = switch (track.stableBand) {
      ProximityBand.distant => 0.0,
      ProximityBand.attention => 100.0,
      ProximityBand.veryNear => 200.0,
    };
    final calibration = policy.calibrations[track.kind]!;
    final persistence = math.min(track.seenFrames, 20) / 20;
    return bandWeight +
        calibration.riskWeight * 10 +
        _centrality(track.boundingBox) * 5 +
        persistence;
  }

  void _record(ProximityAlertEvent event) {
    _lastAlert = event;
    _lastAlertByKindAndBand[(event.kind, event.band)] = event.occurredAt;
    _eventHistory.add(event);
    if (_eventHistory.length > policy.maximumEventHistory) {
      _eventHistory.removeRange(
        0,
        _eventHistory.length - policy.maximumEventHistory,
      );
    }
  }
}

final class _TrackedObject {
  _TrackedObject({
    required this.id,
    required this.kind,
    required this.boundingBox,
    required this.smoothedScore,
    required this.stableBand,
    required this.pendingBand,
    required this.pendingBandFrames,
    required this.lastSeenAt,
  });

  factory _TrackedObject.create({
    required int id,
    required DetectedObject detection,
    required DateTime capturedAt,
    required ProximityPolicy policy,
  }) {
    final score = _rawScore(detection, policy);
    final candidate = _baseBand(score, policy);
    return _TrackedObject(
      id: id,
      kind: detection.kind,
      boundingBox: detection.boundingBox,
      smoothedScore: score,
      stableBand: ProximityBand.distant,
      pendingBand: candidate == ProximityBand.distant ? null : candidate,
      pendingBandFrames: candidate == ProximityBand.distant ? 0 : 1,
      lastSeenAt: capturedAt,
    );
  }

  final int id;
  final DetectedObjectKind kind;
  NormalizedBoundingBox boundingBox;
  double smoothedScore;
  ProximityBand stableBand;
  ProximityBand? pendingBand;
  int pendingBandFrames;
  DateTime lastSeenAt;
  int seenFrames = 1;
  int missedFrames = 0;
  DateTime? lastAlertAt;
  ProximityBand? lastAlertBand;

  void update(
    DetectedObject detection,
    DateTime capturedAt,
    ProximityPolicy policy,
  ) {
    boundingBox = detection.boundingBox;
    lastSeenAt = capturedAt;
    missedFrames = 0;
    seenFrames++;
    final current = _rawScore(detection, policy);
    smoothedScore =
        policy.emaAlpha * current + (1 - policy.emaAlpha) * smoothedScore;
    final candidate = _bandWithHysteresis(smoothedScore, stableBand, policy);
    if (candidate == stableBand) {
      pendingBand = null;
      pendingBandFrames = 0;
      return;
    }
    if (candidate == pendingBand) {
      pendingBandFrames++;
    } else {
      pendingBand = candidate;
      pendingBandFrames = 1;
    }
    final requiredFrames = seenFrames <= policy.minimumTrackFrames
        ? policy.minimumTrackFrames
        : policy.transitionConfirmationFrames;
    if (pendingBandFrames >= requiredFrames) {
      stableBand = candidate;
      pendingBand = null;
      pendingBandFrames = 0;
    }
  }
}

final class _Association {
  const _Association({
    required this.trackId,
    required this.detectionIndex,
    required this.overlap,
  });

  final int trackId;
  final int detectionIndex;
  final double overlap;
}

double _rawScore(DetectedObject detection, ProximityPolicy policy) {
  final box = detection.boundingBox;
  final area = (box.right - box.left) * (box.bottom - box.top);
  final calibration = policy.calibrations[detection.kind]!;
  final relativeFootprint = (math.sqrt(area) / calibration.referenceLinearSize)
      .clamp(0.0, 1.0);
  return (relativeFootprint * 0.70 + box.bottom * 0.30).clamp(0.0, 1.0);
}

ProximityBand _baseBand(double score, ProximityPolicy policy) {
  if (score >= policy.veryNearThreshold) {
    return ProximityBand.veryNear;
  }
  if (score >= policy.attentionThreshold) {
    return ProximityBand.attention;
  }
  return ProximityBand.distant;
}

ProximityBand _bandWithHysteresis(
  double score,
  ProximityBand current,
  ProximityPolicy policy,
) {
  final attentionEnter = policy.attentionThreshold + policy.hysteresisMargin;
  final attentionExit = policy.attentionThreshold - policy.hysteresisMargin;
  final veryNearEnter = policy.veryNearThreshold + policy.hysteresisMargin;
  final veryNearExit = policy.veryNearThreshold - policy.hysteresisMargin;
  return switch (current) {
    ProximityBand.distant =>
      score >= veryNearEnter
          ? ProximityBand.veryNear
          : score >= attentionEnter
          ? ProximityBand.attention
          : ProximityBand.distant,
    ProximityBand.attention =>
      score >= veryNearEnter
          ? ProximityBand.veryNear
          : score <= attentionExit
          ? ProximityBand.distant
          : ProximityBand.attention,
    ProximityBand.veryNear =>
      score <= attentionExit
          ? ProximityBand.distant
          : score <= veryNearExit
          ? ProximityBand.attention
          : ProximityBand.veryNear,
  };
}

double _centrality(NormalizedBoundingBox box) {
  final center = (box.left + box.right) / 2;
  return (1 - (center - 0.5).abs() / 0.5).clamp(0.0, 1.0);
}

double _intersectionOverUnion(
  NormalizedBoundingBox first,
  NormalizedBoundingBox second,
) {
  final left = math.max(first.left, second.left);
  final top = math.max(first.top, second.top);
  final right = math.min(first.right, second.right);
  final bottom = math.min(first.bottom, second.bottom);
  final intersection =
      math.max(0.0, right - left) * math.max(0.0, bottom - top);
  final firstArea = (first.right - first.left) * (first.bottom - first.top);
  final secondArea =
      (second.right - second.left) * (second.bottom - second.top);
  final union = firstArea + secondArea - intersection;
  return union <= 0 ? 0 : intersection / union;
}
