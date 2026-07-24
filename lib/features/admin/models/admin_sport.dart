class SportOption {
  const SportOption({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

class PositionOption {
  const PositionOption({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

enum SportRequestStatus { pending, approved, rejected }

class SportRequest {
  const SportRequest({
    required this.id,
    required this.requesterUserId,
    required this.requestedSportId,
    required this.requestedDisplayName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterUserId;
  final String requestedSportId;
  final String requestedDisplayName;
  final String? message;
  final SportRequestStatus status;
  final DateTime createdAt;

  static SportRequestStatus parseStatus(String raw) {
    return switch (raw) {
      'approved' => SportRequestStatus.approved,
      'rejected' => SportRequestStatus.rejected,
      _ => SportRequestStatus.pending,
    };
  }
}
