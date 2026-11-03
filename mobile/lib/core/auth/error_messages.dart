import '../localization/app_strings.dart';
import 'api_exception.dart';

/// Maps an error to a localised, non-technical message. Branches on
/// `error.code` (API_CONTRACTS.md §1.2), never on server message text.
String apiErrorMessage(Object e, {String unauthenticatedKey = 'session_expired', String conflictKey = 'err_conflict'}) {
  if (e is! ApiException) return AppStrings.t('err_generic');
  switch (e.code) {
    case 'NETWORK':
      return AppStrings.t('err_network');
    case 'RATE_LIMITED':
      return AppStrings.t('err_rate_limited');
    case 'ROLE_MISMATCH':
      return AppStrings.t('err_wrong_role_vet');
    case 'UNAUTHENTICATED':
      return AppStrings.t(unauthenticatedKey);
    case 'FORBIDDEN':
      return AppStrings.t('err_forbidden');
    case 'NOT_FOUND':
      return AppStrings.t('err_not_found');
    case 'CONFLICT':
      return AppStrings.t(conflictKey);
    case 'VALIDATION_ERROR':
      return e.issue ?? AppStrings.t('err_generic');
    case 'UPSTREAM_UNAVAILABLE':
      return AppStrings.t('err_network');
    default:
      return AppStrings.t('err_generic');
  }
}

