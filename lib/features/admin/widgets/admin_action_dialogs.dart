import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:flutter/material.dart';

class AdminRequestReviewDialogResult {
  const AdminRequestReviewDialogResult({
    required this.decisionNote,
    required this.createClubIfMissing,
  });

  final String decisionNote;
  final bool createClubIfMissing;
}

class AdminSportRequestReviewDialogResult {
  const AdminSportRequestReviewDialogResult({required this.decisionNote});

  final String decisionNote;
}

Future<AdminRequestReviewDialogResult?> showAdminAccessRequestReviewDialog(
  BuildContext context,
  AdminScope scope,
  AdminAccessRequest request,
  bool approve,
) async {
  final noteController = TextEditingController();
  var createClubIfMissing = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(approve ? 'Anfrage genehmigen' : 'Anfrage ablehnen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verein: ${request.clubName ?? request.requestedClubName}'),
                const SizedBox(height: 8),
                if (request.isForMissingClub)
                  Text(
                    scope.isGlobalAdmin
                        ? 'Dieser Verein existiert noch nicht. Du kannst ihn beim Genehmigen direkt anlegen.'
                        : 'Dieser Verein existiert noch nicht. Das darf nur ein Super-Admin genehmigen.',
                    style: TextStyle(
                      color: scope.isGlobalAdmin
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (approve &&
                    request.isForMissingClub &&
                    scope.isGlobalAdmin) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: createClubIfMissing,
                    onChanged: (value) {
                      setDialogState(() {
                        createClubIfMissing = value ?? false;
                      });
                    },
                    title: const Text(
                      'Verein bei Genehmigung automatisch anlegen',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notiz (optional)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(approve ? 'Genehmigen' : 'Ablehnen'),
              ),
            ],
          );
        },
      );
    },
  );

  try {
    if (confirmed != true) {
      return null;
    }

    return AdminRequestReviewDialogResult(
      decisionNote: noteController.text.trim(),
      createClubIfMissing: createClubIfMissing,
    );
  } finally {
    noteController.dispose();
  }
}

Future<AdminSportRequestReviewDialogResult?>
    showSportRequestReviewDialog(
  BuildContext context,
  SportRequest request,
  bool approve,
) async {
  final noteController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(approve ? 'Sportart genehmigen' : 'Sportart ablehnen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${request.requestedDisplayName} (${request.requestedSportId})'),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notiz (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(approve ? 'Genehmigen' : 'Ablehnen'),
        ),
      ],
    ),
  );

  try {
    if (confirmed != true) {
      return null;
    }

    return AdminSportRequestReviewDialogResult(
      decisionNote: noteController.text.trim(),
    );
  } finally {
    noteController.dispose();
  }
}

Future<bool?> showRemoveClubAdminRoleDialog(
  BuildContext context,
  ClubAdminRoleAssignment assignment,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rolle entziehen?'),
      content: Text(
        'Soll ${assignment.email ?? assignment.userId} als Vereinsadmin fuer ${assignment.clubName} entfernt werden?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Entziehen'),
        ),
      ],
    ),
  );
}