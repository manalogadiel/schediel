class BackendDeletion {
  const BackendDeletion({required this.deletionJobId, required this.status, required this.requestedAt,
    required this.completedAt, required this.revokedShareCount, required this.deletedShareCount});
  factory BackendDeletion.fromJson(Map<String,dynamic> j) => BackendDeletion(
    deletionJobId:j['deletionJobId'] as String,status:j['status'] as String,
    requestedAt:DateTime.parse(j['requestedAt'] as String),completedAt:j['completedAt']==null?null:DateTime.parse(j['completedAt'] as String),
    revokedShareCount:(j['revokedShareCount'] as num).toInt(),deletedShareCount:(j['deletedShareCount'] as num).toInt());
  final String deletionJobId;
  final String status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final int revokedShareCount;
  final int deletedShareCount;
}
abstract class BackendDataApi {
  /// The signed-in online identity, without signing in; null when absent.
  Future<String?> currentOwnerId();
  /// Sends as [expectedOwnerId] only; fails with 401 if the session changed.
  Future<BackendDeletion> deleteBackendData(String idempotencyKey, {required String expectedOwnerId});
  Future<BackendDeletion> deletionJob(String jobId);
}

/// The saved deletion command can no longer be replayed by the server. A new
/// command needs the user's explicit confirmation.
class BackendDeletionExpired implements Exception {
  const BackendDeletionExpired();
  @override
  String toString() => 'BackendDeletionExpired';
}
