import '../../l10n/app_localizations.dart';

/// Nhãn đã dịch và tông màu cho các trạng thái (varchar) của backend PBMS.
enum StatusTone { neutral, accent, success, warning, danger }

class StatusInfo {
  final String label;
  final StatusTone tone;

  const StatusInfo(this.label, this.tone);
}

class StatusLabels {
  StatusLabels._();

  static String _k(String? s) => (s ?? '').trim().toLowerCase();

  static StatusInfo _unknown(AppLocalizations t, String? s) => StatusInfo(
      (s == null || s.isEmpty) ? t.commonUnknown : s, StatusTone.neutral);

  static StatusInfo reservation(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'pending':
        return StatusInfo(t.stReservationPending, StatusTone.warning);
      case 'confirmed':
        return StatusInfo(t.stReservationConfirmed, StatusTone.success);
      case 'modified':
        return StatusInfo(t.stReservationModified, StatusTone.success);
      case 'checkedin':
        return StatusInfo(t.stReservationCheckedIn, StatusTone.accent);
      case 'completed':
        return StatusInfo(t.stReservationCompleted, StatusTone.neutral);
      case 'cancelled':
        return StatusInfo(t.stCancelled, StatusTone.neutral);
      case 'noshow':
        return StatusInfo(t.stReservationNoShow, StatusTone.danger);
      default:
        return _unknown(t, status);
    }
  }

  static StatusInfo session(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'active':
        return StatusInfo(t.stSessionActive, StatusTone.accent);
      case 'completed':
        return StatusInfo(t.stSessionCompleted, StatusTone.neutral);
      case 'exception':
        return StatusInfo(t.stSessionException, StatusTone.danger);
      default:
        return _unknown(t, status);
    }
  }

  static StatusInfo subscription(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'active':
        return StatusInfo(t.stPassActive, StatusTone.success);
      case 'pendingpayment':
        return StatusInfo(t.stPendingPayment, StatusTone.warning);
      case 'cancelled':
        return StatusInfo(t.stCancelled, StatusTone.neutral);
      case 'expired':
        return StatusInfo(t.stPassExpired, StatusTone.danger);
      default:
        return _unknown(t, status);
    }
  }

  static StatusInfo payment(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'success':
        return StatusInfo(t.stPaid, StatusTone.success);
      case 'pending':
        return StatusInfo(t.stPendingPayment, StatusTone.warning);
      case 'failed':
      case 'cancelled':
        return StatusInfo(t.stCancelled, StatusTone.danger);
      default:
        return _unknown(t, status);
    }
  }

  static StatusInfo incident(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'open':
        return StatusInfo(t.stIncidentOpen, StatusTone.warning);
      case 'inprogress':
        return StatusInfo(t.stIncidentInProgress, StatusTone.accent);
      case 'resolved':
        return StatusInfo(t.stIncidentResolved, StatusTone.success);
      case 'cancelled':
        return StatusInfo(t.stCancelled, StatusTone.neutral);
      default:
        return _unknown(t, status);
    }
  }

  static StatusInfo vehicleChange(AppLocalizations t, String? status) {
    switch (_k(status)) {
      case 'pending':
        return StatusInfo(t.stChangePending, StatusTone.warning);
      case 'approved':
        return StatusInfo(t.stChangeApproved, StatusTone.success);
      case 'rejected':
        return StatusInfo(t.stChangeRejected, StatusTone.danger);
      default:
        return _unknown(t, status);
    }
  }

  static String paymentMethod(AppLocalizations t, String? method) {
    switch (_k(method)) {
      case 'payos':
        return t.payMethodPayOS;
      case 'cash':
        return t.payMethodCash;
      default:
        return method ?? '';
    }
  }

  static String paymentType(AppLocalizations t, String? type) {
    switch (_k(type)) {
      case 'deposit':
        return t.payTypeDeposit;
      case 'checkoutfee':
        return t.payTypeCheckout;
      case 'subscriptionfee':
        return t.payTypeSubscription;
      case 'subscriptionrenewal':
        return t.payTypeRenewal;
      default:
        return type ?? '';
    }
  }

  static String role(AppLocalizations t, String? roleName) {
    switch (_k(roleName)) {
      case 'staff':
        return t.roleStaff;
      case 'manager':
        return t.roleManager;
      case 'admin':
        return t.roleAdmin;
      default:
        return t.roleCustomer;
    }
  }
}
