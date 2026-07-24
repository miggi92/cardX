import 'dart:async';

import 'package:cardx/core/providers/admin_provider.dart';
import 'package:cardx/core/providers/storage_image_provider.dart';
import 'package:cardx/core/repositories/supabase_admin_repository.dart';
import 'package:cardx/features/admin/models/admin_access_request.dart';
import 'package:cardx/features/admin/models/admin_role_assignment.dart';
import 'package:cardx/features/admin/models/admin_scope.dart';
import 'package:cardx/features/admin/models/admin_sport.dart';
import 'package:cardx/features/admin/views/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const testScope = AdminScope(
    isGlobalAdmin: false,
    clubs: [
      AdminClubPermission(
        clubId: 'club-1',
        clubName: 'FC Test',
        canCreatePlayers: true,
        canEditPlayers: true,
      ),
    ],
  );

  const testSports = [
    SportOption(id: 'soccer', displayName: 'Soccer'),
    SportOption(id: 'handball', displayName: 'Handball'),
  ];

  testWidgets('shows sport request section and validates required fields', (
    tester,
  ) async {
    final fakeRepo = _FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepoProvider.overrideWithValue(fakeRepo),
          storageImageResolverProvider.overrideWithValue(_TestImageResolver()),
          adminScopeProvider.overrideWith((ref) => testScope),
          sportsProvider.overrideWith((ref) => testSports),
          pendingAdminAccessRequestsProvider.overrideWith(
            (ref) => const <AdminAccessRequest>[],
          ),
          adminPlayersByClubProvider.overrideWith(
            (ref, clubId) => const <AdminPlayer>[],
          ),
          pendingSportRequestsProvider.overrideWith(
            (ref) => const <SportRequest>[],
          ),
          clubAdminRoleAssignmentsProvider.overrideWith(
            (ref) => const <ClubAdminRoleAssignment>[],
          ),
        ],
        child: const MaterialApp(
          home: ExcludeSemantics(child: AdminDashboardScreen()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Neue Sportart beantragen'), findsOneWidget);

    final sportRequestForm = find.ancestor(
      of: find.text('Neue Sportart beantragen'),
      matching: find.byType(Form),
    );
    final submitButtonFinder = find.descendant(
      of: sportRequestForm,
      matching: find.byType(FilledButton),
    );
    final submitButton = tester.widget<FilledButton>(submitButtonFinder);

    submitButton.onPressed?.call();
    await tester.pump();

    expect(find.text('Pflichtfeld'), findsNWidgets(2));
    expect(fakeRepo.submitSportRequestCallCount, 0);
  });

  testWidgets('submits sport request with entered values', (tester) async {
    final fakeRepo = _FakeAdminRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepoProvider.overrideWithValue(fakeRepo),
          storageImageResolverProvider.overrideWithValue(_TestImageResolver()),
          adminScopeProvider.overrideWith((ref) => testScope),
          sportsProvider.overrideWith((ref) => testSports),
          pendingAdminAccessRequestsProvider.overrideWith(
            (ref) => const <AdminAccessRequest>[],
          ),
          adminPlayersByClubProvider.overrideWith(
            (ref, clubId) => const <AdminPlayer>[],
          ),
          pendingSportRequestsProvider.overrideWith(
            (ref) => const <SportRequest>[],
          ),
          clubAdminRoleAssignmentsProvider.overrideWith(
            (ref) => const <ClubAdminRoleAssignment>[],
          ),
        ],
        child: const MaterialApp(
          home: ExcludeSemantics(child: AdminDashboardScreen()),
        ),
      ),
    );

    await tester.pump();

    final sportRequestForm = find.ancestor(
      of: find.text('Neue Sportart beantragen'),
      matching: find.byType(Form),
    );
    final fields = find.descendant(
      of: sportRequestForm,
      matching: find.byType(TextFormField),
    );

    await tester.enterText(fields.at(0), 'ice_hockey');
    await tester.enterText(fields.at(1), 'Ice Hockey');
    await tester.enterText(fields.at(2), 'Bitte fuer Winterliga aufnehmen.');

    final submitButtonFinder = find.descendant(
      of: sportRequestForm,
      matching: find.byType(FilledButton),
    );
    final submitButton = tester.widget<FilledButton>(submitButtonFinder);
    submitButton.onPressed?.call();
    await tester.pump();

    expect(fakeRepo.submitSportRequestCallCount, 1);
    expect(fakeRepo.lastSportId, 'ice_hockey');
    expect(fakeRepo.lastDisplayName, 'Ice Hockey');
    expect(fakeRepo.lastMessage, 'Bitte fuer Winterliga aufnehmen.');
    expect(find.text('Sportart-Anfrage gesendet.'), findsOneWidget);
  });
}

class _TestImageResolver extends SupabaseStorageImageResolver {
  _TestImageResolver() : super(supabase: _buildTestSupabaseClient());

  final Completer<String> _neverCompletes = Completer<String>();

  @override
  Future<String> resolveImageUrl({
    required String bucketName,
    required String objectId,
    required bool isPublic,
    int signedUrlLifetimeSeconds = 60 * 60 * 24,
  }) async {
    return _neverCompletes.future;
  }
}

class _FakeAdminRepository extends SupabaseAdminRepository {
  _FakeAdminRepository()
    : super(
        imageResolver: _TestImageResolver(),
        supabase: _buildTestSupabaseClient(),
      );

  int submitSportRequestCallCount = 0;
  String? lastSportId;
  String? lastDisplayName;
  String? lastMessage;

  @override
  Future<String> submitSportRequest({
    required String sportId,
    required String displayName,
    String? message,
  }) async {
    submitSportRequestCallCount += 1;
    lastSportId = sportId;
    lastDisplayName = displayName;
    lastMessage = message;
    return 'req-1';
  }
}

SupabaseClient _buildTestSupabaseClient() {
  return SupabaseClient(
    'https://example.com',
    'test-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}
