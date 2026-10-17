import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neonecy_team_app/core/theme/app_theme.dart';
import 'package:neonecy_team_app/features/leads/data/services/location_search_service.dart';
import 'package:neonecy_team_app/features/leads/domain/models/lead.dart';
import 'package:neonecy_team_app/features/leads/presentation/widgets/add_lead_step1.dart';

void main() {
  test('Lead model serializes and parses coordinates', () {
    final lead = Lead(
      id: 'lead_test_1',
      company: 'Test Resort',
      type: 'Resort',
      location: "Cox's Bazar",
      status: 'New',
      priority: 'High',
      createdAt: DateTime.now(),
      latitude: 21.4272,
      longitude: 92.0058,
    );

    expect(lead.hasCoordinates, isTrue);
    expect(lead.coordinatesFormatted, '21.427200, 92.005800');

    final json = lead.toJson();
    expect(json['latitude'], 21.4272);
    expect(json['longitude'], 92.0058);

    final restored = Lead.fromJson(json);
    expect(restored.latitude, 21.4272);
    expect(restored.longitude, 92.0058);

    final apiPayload = lead.toApiPayload();
    expect(apiPayload['latitude'], 21.4272);
    expect(apiPayload['longitude'], 92.0058);
  });

  test('LocationSearchService fallback matches popular hubs', () async {
    final results = await LocationSearchService.instance.search('Cox');
    expect(results.isNotEmpty, isTrue);
    expect(results.first.title, contains("Cox's Bazar"));
  });

  testWidgets('AddLeadStep1 shows Pick on Map action and coordinate badge',
      (tester) async {
    final companyCtrl = TextEditingController(text: 'Sea Pearl');
    final locationCtrl = TextEditingController(text: "Cox's Bazar");

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [NecColors.light()]),
        home: Scaffold(
          body: AddLeadStep1(
            companyController: companyCtrl,
            locationController: locationCtrl,
            selectedBusinessType: 'Hotel',
            latitude: 21.4272,
            longitude: 92.0058,
            onBusinessTypeChanged: (_) {},
            onNext: () {},
          ),
        ),
      ),
    );

    expect(find.text('Pick on Map'), findsOneWidget);
    expect(find.textContaining('Coordinates: 21.42720, 92.00580'), findsOneWidget);
  });
}
