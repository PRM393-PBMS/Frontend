import 'package:equatable/equatable.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_read.dart';

class IncidentReport extends Equatable {
  final String id;
  final String? sessionId;
  final String? reporterName;
  final String issueType;
  final String description;
  final String? proofImageUrl;
  final String status;
  final String? handledByStaffId;
  final String? handledByStaffName;
  final DateTime? resolvedAt;
  final String? resolutionNotes;

  const IncidentReport({
    required this.id,
    required this.sessionId,
    required this.reporterName,
    required this.issueType,
    required this.description,
    required this.proofImageUrl,
    required this.status,
    required this.handledByStaffId,
    required this.handledByStaffName,
    required this.resolvedAt,
    required this.resolutionNotes,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> j) => IncidentReport(
        id: j.str('incidentId'),
        sessionId: j.strOrNull('sessionId'),
        reporterName: j.strOrNull('reportedByUserFullName'),
        issueType: j.str('issueType'),
        description: j.str('description'),
        proofImageUrl: j.strOrNull('proofImageUrl'),
        status: j.str('status'),
        handledByStaffId: j.strOrNull('handledByStaffId'),
        handledByStaffName: j.strOrNull('handledByStaffFullName'),
        resolvedAt: j.date('resolvedAt'),
        resolutionNotes: j.strOrNull('resolutionNotes'),
      );

  String get _s => status.trim().toLowerCase();
  bool get isOpen => _s == 'open';
  bool get isInProgress => _s == 'inprogress';
  bool get isResolved => _s == 'resolved';

  @override
  List<Object?> get props => [id, status, handledByStaffId, resolutionNotes];
}

class IncidentRepository {
  final ApiClient _api;

  IncidentRepository(this._api);

  Future<List<IncidentReport>> mine() =>
      _api.getList(ApiEndpoints.myIncidents, IncidentReport.fromJson);

  /// Staff / Manager. Backend trả 404 khi chưa có sự cố nào.
  Future<List<IncidentReport>> all() =>
      _api.getList(ApiEndpoints.incidents, IncidentReport.fromJson);

  Future<IncidentReport> byId(String id) async {
    final res = await _api.get<dynamic>(ApiEndpoints.incidentById(id));
    return IncidentReport.fromJson(res.result as Map<String, dynamic>);
  }

  Future<String?> uploadProof(UploadFile file) async {
    final raw = await _api.upload(ApiEndpoints.uploadIncidentProof, file);
    if (raw is Map<String, dynamic>) return raw.strOrNull('imageUrl');
    return null;
  }

  Future<IncidentReport> create({
    required String issueType,
    required String description,
    String? sessionId,
    String? proofImageUrl,
  }) async {
    final res = await _api.post<dynamic>(ApiEndpoints.incidents, data: {
      'issueType': issueType.trim(),
      'description': description.trim(),
      if (sessionId != null) 'sessionId': sessionId,
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
    });
    return IncidentReport.fromJson(res.result as Map<String, dynamic>);
  }

  Future<IncidentReport> assign(String incidentId, String staffId) async {
    final res = await _api
        .put<dynamic>(ApiEndpoints.assignIncident(incidentId, staffId));
    return IncidentReport.fromJson(res.result as Map<String, dynamic>);
  }

  Future<IncidentReport> resolve(
      String incidentId, String staffId, String notes) async {
    final res = await _api.put<dynamic>(
      ApiEndpoints.resolveIncident(incidentId, staffId),
      data: {'resolutionNotes': notes.trim()},
    );
    return IncidentReport.fromJson(res.result as Map<String, dynamic>);
  }
}
