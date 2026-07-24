enum AdminRequestStatus { pending, approved, rejected }

class AdminAccessRequest {
  const AdminAccessRequest({
    required this.id,
    required this.requesterUserId,
    required this.clubId,
    required this.requestedClubName,
    required this.message,
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.decisionNote,
    required this.createdAt,
    required this.clubName,
  });

  final String id;
  final String requesterUserId;
  final String? clubId;
  final String requestedClubName;
  final String? message;
  final AdminRequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? decisionNote;
  final DateTime createdAt;
  final String? clubName;

  bool get isForMissingClub => clubId == null;

  static AdminRequestStatus parseStatus(String raw) {
    return switch (raw) {
      'approved' => AdminRequestStatus.approved,
      'rejected' => AdminRequestStatus.rejected,
      _ => AdminRequestStatus.pending,
    };
  }
}
