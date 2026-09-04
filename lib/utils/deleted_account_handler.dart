import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../theme/app_constants.dart';
import '../theme/app_theme.dart';

/// Detects the "account is Deleted" 403 shape returned by login endpoints
/// and, if it matches, offers the user a way into the recovery flow.
///
/// Returns true if [error] was handled (caller should skip its normal
/// error snackbar); false if [error] is unrelated and should be handled
/// as usual.
Future<bool> handleDeletedAccountError(
  BuildContext context,
  Object error, {
  required String identifier,
  required String identifierType,
}) async {
  if (error is! ApiException || error.statusCode != 403) return false;
  final status = (error.body['data'] as Map?)?['status'];
  if (status != 'Deleted') return false;
  if (!context.mounted) return false;

  final recover = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Account Deleted',
        style: TextStyle(
          fontFamily: 'Jost',
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: Color(0xFF0A2540),
        ),
      ),
      content: const Text(
        'This account has been deleted. You can recover it or start fresh.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.limeGreen,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'Recover Account',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: AppColors.navyBlue,
            ),
          ),
        ),
      ],
    ),
  );

  if (recover == true && context.mounted) {
    Navigator.pushNamed(
      context,
      AppRoutes.accountRecovery,
      arguments: {'identifier': identifier, 'identifierType': identifierType},
    );
  }
  return true;
}
