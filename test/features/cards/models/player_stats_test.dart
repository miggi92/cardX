import 'package:cardx/features/cards/models/player_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps statistics for multiple teams and uses the latest totals', () {
    final stats = PlayerStats.fromSupabase(
      legacyStats: {'goals': 3, 'games': 4},
      memberships: [
        {
          'is_active': true,
          'club_season_teams': {
            'team_name': 'TV Flein 1',
            'season_id': '2025/26',
            'age_group': 'adults',
            'gender': 'male',
            'sport_id': 'handball',
            'league_id': 'oberliga',
          },
          'player_team_stats': {
            'stats': {'goals': 20, 'gamesPlayed': 8},
            'last_synced_at': '2026-08-04T12:00:00Z',
          },
        },
        {
          'is_active': true,
          'club_season_teams': {
            'team_name': 'TV Flein 2',
            'season_id': '2025/26',
            'age_group': 'adults',
            'gender': 'male',
            'sport_id': 'handball',
            'league_id': 'bezirksliga',
          },
          'player_team_stats': [
            {
              'stats': {'goals': 31, 'gamesPlayed': 11, 'redCards': 1},
              'last_synced_at': '2026-08-05T12:00:00Z',
            },
          ],
        },
      ],
    );

    expect(stats.goals, 31);
    expect(stats.games, 11);
    expect(stats.teams, hasLength(2));
    expect(stats.teams.first.teamName, 'TV Flein 2');
    expect(stats.teams.first.integerValue('redCards'), 1);
  });

  test('round-trips team statistics through cached card JSON', () {
    const original = PlayerStats(
      goals: 12,
      games: 5,
      teams: [
        PlayerTeamStats(
          teamName: 'A-Jugend',
          season: '2025/26',
          ageGroup: 'A-Jugend',
          gender: 'female',
          sport: 'handball',
          league: 'oberliga',
          values: {'goals': 12, 'gamesPlayed': 5},
        ),
      ],
    );

    final restored = PlayerStats.fromJson(original.toJson());

    expect(restored.goals, original.goals);
    expect(restored.teams.single.teamName, 'A-Jugend');
    expect(restored.teams.single.values, original.teams.single.values);
  });

  test('falls back to legacy statistics without team data', () {
    final stats = PlayerStats.fromSupabase(
      legacyStats: [
        {'goals': 7, 'games': 9},
      ],
      memberships: const [],
    );

    expect(stats.goals, 7);
    expect(stats.games, 9);
    expect(stats.teams, isEmpty);
  });
}
