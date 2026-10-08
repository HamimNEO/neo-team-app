import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/policy_model.dart';

class PolicyRepository {
  PolicyRepository._();

  static final PolicyRepository instance = PolicyRepository._();

  static const String _apiEndpoint =
      'https://hamimneo.github.io/necTeam-official/api/policies.json';
  static const String _webBaseUrl =
      'https://hamimneo.github.io/necTeam-official';

  final Map<String, PolicyModel> _memoryCache = {};

  static final Map<String, PolicyModel> _bundledPolicies = {
    'privacy-policy': const PolicyModel(
      key: 'privacy-policy',
      title: "Privacy Policy",
      label: "Your privacy",
      icon: "shield",
      description:
          "How NEC TEAM handles information during our pre-release testing phase.",
      intro:
          "This policy explains how NEONECY handles information in NEC TEAM and on this website. It covers the current internal and closed-testing demo, which stores workplace records locally rather than in a connected company backend.",
      sections: [
        PolicySection(
          title: "Who we are",
          paragraphs: [
            "NEC TEAM is a workplace and CRM app provided by NEONECY. For privacy questions, data requests or help with this policy, contact bingi.startup@gmail.com."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Information you enter",
          paragraphs: [
            "The demo can store employee names, work emails, phone numbers, profile photos, employment details, personal and emergency contact details, salary and deduction information, leads and client contacts, tasks, attendance and leave requests, lunch preferences, messages and selected attachments. These records support the features you choose to use and are stored on the device in this testing version.",
            "Demo accounts and administrator-managed login credentials are also stored locally. Administrators can view a stored staff password or reset it after verifying their own password. This demo is not intended for real employee, payroll or confidential business information; use sample data and a password you do not use elsewhere."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Device information and Firebase services",
          paragraphs: [
            "The app includes Google Firebase Analytics, Crashlytics and Cloud Messaging. When configured and active, these services process app interactions, installation or app-instance identifiers, device and operating-system information, notification tokens, and diagnostic information such as crash reports and error logs. Crash reporting is enabled in release builds; Analytics can automatically record usage events.",
            "These services may transmit technical information to Google even though workplace records do not synchronize to a company backend. Firebase and related Google services can process information outside your country under their applicable terms and privacy policies."
          ],
          items: [],
          links: [
            PolicyLink(
                label: "Firebase privacy and security information",
                href: "https://firebase.google.com/support/privacy"),
            PolicyLink(
                label: "Google Privacy Policy",
                href: "https://policies.google.com/privacy")
          ],
        ),
        PolicySection(
          title: "Permissions and selected files",
          paragraphs: [
            "Camera, photo library and file access support profile pictures and message attachments you choose. Notifications support app alerts. Your operating system controls these permissions and you can change them in device settings.",
            "The Android app declares location and media permissions. The current demo does not implement live location tracking or background location collection. Visit addresses entered in the app are workplace records, not a live device-location history. See the Data Collection page for a summary of the current data categories."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Use and disclosure",
          paragraphs: [
            "We use information to provide the selected app features, handle support requests, understand app usage and diagnose problems. Local role settings demonstrate employee and administrator access on that device; they do not provide production server authorization or cross-device access.",
            "This demo does not include advertising or sell user data. Technical information may be processed by the Firebase services described above. If you contact us by email, your email provider and our email provider process the message, and we use the information you send to respond to your request."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Retention, security and deletion",
          paragraphs: [
            "Local records remain on the device until you remove the app’s stored data or delete the app, subject to operating-system backup and restore behavior. Signing out alone does not delete all local records. Saved attachments or exports outside the app must be removed separately.",
            "Firebase technical data follows the retention settings and policies of the relevant Google service. Support messages are kept as needed to resolve the request and meet applicable obligations. Contact us for help with information held under our control; any retention exception will be explained in our response.",
            "The demo does not promise encrypted local storage or production-grade account security. For instructions and a contact route for account or data-deletion requests, visit Data Deletion."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Your choices and policy changes",
          paragraphs: [
            "You can edit your own available profile fields, change your password, control device permissions, clear local app data and contact us about access, correction or deletion. Administrators control employee access in the demo.",
            "NEC TEAM is intended for workplace users, not children. If you believe a child’s personal information has been provided, contact us. We will update this page when the app’s data practices change, including before introducing connected workplace accounts or a company backend. The date above identifies this policy version."
          ],
          items: [],
          links: [],
        )
      ],
      requestForm: false,
      webUrl: 'https://hamimneo.github.io/necTeam-official/privacy-policy/',
    ),
    'terms-and-conditions': const PolicyModel(
      key: 'terms-and-conditions',
      title: "Terms & Conditions",
      label: "The essentials",
      icon: "document",
      description:
          "A few clear ground rules for using NEC TEAM and its testing releases.",
      intro:
          "These terms apply to the NEC TEAM app and this website, provided by NEONECY. By using them, you agree to these terms. If you do not agree, please do not use the app.",
      sections: [
        PolicySection(
          title: "A pre-release workplace demo",
          paragraphs: [
            "The current version is offered for internal or closed testing and feedback. It demonstrates people management, CRM, attendance, leave, lunch preferences, tasks, messages and administration using local or sample records. Public store downloads are not yet available.",
            "The demo is not a connected company service. Messages are not delivered between separate devices, and local attendance, salary or administrative changes do not constitute an official payroll record, leave approval or company instruction. Features may change or be removed as development continues."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Accounts and your responsibilities",
          paragraphs: [
            "Use only test accounts or accounts your organization has authorized you to use. Do not enter real confidential workplace information into this demo. Keep your device and login credentials protected, and use a unique test password.",
            "Administrators are responsible for the access they grant and the records they enter. Verified administrators can reveal available staff passwords or set a new password in this demo. Staff can change their own passwords. You must have permission to add another person’s information or upload their files."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Acceptable use",
          paragraphs: [],
          items: [
            "Use the app lawfully and respect other people’s privacy.",
            "Do not impersonate another person or attempt unauthorized access.",
            "Do not upload unlawful, abusive or harmful content.",
            "Do not interfere with the app, misuse its services or infringe intellectual property rights."
          ],
          links: [],
        ),
        PolicySection(
          title: "Your content and our materials",
          paragraphs: [
            "You retain your rights in the content you enter. You are responsible for its accuracy, lawfulness and any permissions needed to use it. Local content is processed to provide the demo features you select.",
            "The app, website, logos and original interface materials belong to NEONECY or their respective owners. We grant you a limited permission to use this testing version for its intended purpose; this does not transfer ownership of those materials."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Availability and limitations",
          paragraphs: [
            "Testing releases may contain errors, lose local data or be unavailable. They are not a substitute for an official company record or a production system. Keep any necessary records independently.",
            "To the extent permitted by applicable law, the testing app is provided as available without guarantees of continuous availability, accuracy or fitness for a particular purpose. These terms do not exclude rights or liabilities that applicable law does not allow us to exclude."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Privacy, ending use and changes",
          paragraphs: [
            "Our Privacy Policy explains how information is handled. You can stop using the app and remove its local data at any time. Data Deletion explains the available steps and how to request assistance.",
            "We may update these terms as the service changes. Material changes will be reflected on this page with an updated date. For questions about these terms, contact bingi.startup@gmail.com."
          ],
          items: [],
          links: [],
        )
      ],
      requestForm: false,
      webUrl:
          'https://hamimneo.github.io/necTeam-official/terms-and-conditions/',
    ),
    'data-deletion': const PolicyModel(
      key: 'data-deletion',
      title: "Account & Data Deletion",
      label: "Your data, your choice",
      icon: "trash",
      description:
          "Clear local demo data or ask NEONECY for help deleting information.",
      intro:
          "NEC TEAM’s current testing version does not create a hosted workplace account or synchronize workplace records to a company backend. You can remove the demo data from your device and contact NEONECY about any information held under our control.",
      sections: [
        PolicySection(
          title: "Delete local data on Android",
          paragraphs: [],
          items: [
            "Open your device Settings and find Apps → NEC TEAM.",
            "Open Storage or Storage & cache, then choose Clear storage / Clear data. The wording varies by device.",
            "This resets local profiles, login credentials, leads, messages, attendance records, lunch preferences and app settings on that device.",
            "Remove separately saved attachments or exports from your Files or Photos app. Signing out alone does not clear all app records."
          ],
          links: [],
        ),
        PolicySection(
          title: "Delete local data on iPhone or iPad",
          paragraphs: [],
          items: [
            "Open Settings → General → iPhone Storage (or iPad Storage) → NEC TEAM.",
            "Choose Delete App, not Offload App, to remove the app and its local data.",
            "Remove separately saved attachments or exports from Files or Photos.",
            "Your device or cloud backup may retain a previous copy. Manage those backups separately with your device or cloud provider. Reinstalling the demo can recreate sample records; those are not restored personal records."
          ],
          links: [],
        ),
        PolicySection(
          title: "Request account or data deletion",
          paragraphs: [
            "Use the request form below or email bingi.startup@gmail.com with the subject “NEC TEAM data deletion request”. Include your work email, the information you want removed and whether you are requesting an account deletion, all data deletion or specific records. Do not include a password or sensitive documents.",
            "We may ask for enough information to verify that the request is yours. We can assist with local deletion and address support correspondence or other information under our control. We cannot remotely erase a device’s local storage."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "What deletion does and does not remove",
          paragraphs: [
            "Clearing app storage removes the local demo records on that device. It does not remove another device’s records, files saved outside the app, operating-system backups, or technical information already processed by Firebase.",
            "Firebase technical-data retention is described in the Privacy Policy and the relevant provider’s policies. If information under our control must be retained to meet an applicable legal obligation, we will explain the scope, reason and retention period when responding to your request. This website does not perform automatic account or cloud-data deletion."
          ],
          items: [],
          links: [],
        )
      ],
      requestForm: true,
      webUrl: 'https://hamimneo.github.io/necTeam-official/data-deletion/',
    ),
    'data-collection': const PolicyModel(
      key: 'data-collection',
      title: "Data Collection",
      label: "A clear overview",
      icon: "database",
      description: "What the app uses, where it goes and why it is needed.",
      intro:
          "This summary describes the current testing build of NEC TEAM. Workplace records are stored locally; some technical information is processed by Google Firebase services. This page complements the Privacy Policy.",
      sections: [
        PolicySection(
          title: "Profile, work and login information",
          paragraphs: [
            "Names, contact information, profile pictures, employment details, personal or emergency details, and administrator-issued login credentials are used to demonstrate employee profiles and account access. These are local demo records. Verified administrators can access available staff passwords."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Workplace and financial records",
          paragraphs: [
            "Leads, client contacts, tasks, attendance times, leave or correction requests, overtime, lunch choices, salary amounts, benefits, deductions and expense records support the matching app features. The demo does not process payments or connect to payroll or banking services. Use sample information only."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Messages, photos and files",
          paragraphs: [
            "Messages, selected photos, camera images and files are stored to display conversations or profile pictures in the demo. There is no cross-device message delivery in the current version. Native pickers and permissions let you select what to provide."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Analytics and diagnostics",
          paragraphs: [
            "Firebase Analytics can collect app interactions, app-instance identifiers and device information. Firebase Crashlytics collects crash reports, stack traces and device or app information in release builds. These services help us understand usage and identify problems. This technical information may be transmitted to Google."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Notifications and location",
          paragraphs: [
            "Firebase Cloud Messaging uses an installation identifier and notification token to support notifications. Device permissions control notification delivery.",
            "The app declares Android location and media permissions. Live device-location tracking is not implemented in this demo. A visit address entered by a user is a workplace record. Review device permissions in Settings and decline access you do not want to grant."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "This website",
          paragraphs: [
            "This site has no added advertising, analytics trackers or nonessential cookies. The deletion form keeps typed values only in the open page and prepares an email draft; it does not upload the form to a server.",
            "When the site is hosted, the hosting provider may process ordinary request logs such as IP addresses, timestamps and browser information to deliver and protect the website. If you send an email, that message is handled by the relevant email providers and NEONECY."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Control and deletion",
          paragraphs: [
            "Use device settings to manage permissions, clear local data or remove the app. See Data Deletion for complete instructions and a request route. See Privacy Policy for service-provider information, retention and contact details."
          ],
          items: [],
          links: [],
        )
      ],
      requestForm: false,
      webUrl: 'https://hamimneo.github.io/necTeam-official/data-collection/',
    ),
    'support': const PolicyModel(
      key: 'support',
      title: "Support & Contact",
      label: "We’re here to help",
      icon: "message",
      description: "Questions, feedback or a little help with NEC TEAM.",
      intro:
          "NEC TEAM is currently in its pre-release testing phase. Contact NEONECY for app questions, testing feedback, privacy requests or deletion assistance.",
      sections: [
        PolicySection(
          title: "Contact NEONECY",
          paragraphs: [
            "Email bingi.startup@gmail.com. Include “NEC TEAM” in the subject so we can identify your request."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Report a problem",
          paragraphs: [],
          items: [
            "Tell us your device model, operating-system version and app version.",
            "Describe the steps that led to the issue and what you expected to happen.",
            "Attach a screenshot only after removing personal, employee or confidential information.",
            "Never send passwords, salary documents or unnecessary identity information."
          ],
          links: [],
        ),
        PolicySection(
          title: "Testing and downloads",
          paragraphs: [
            "Public Google Play and App Store downloads are coming soon. Internal and closed tests are available only through the invitations or links provided by the testing organizer. Store buttons on this website do not install the app."
          ],
          items: [],
          links: [],
        ),
        PolicySection(
          title: "Privacy and deletion requests",
          paragraphs: [
            "Use Privacy Policy and Data Collection to understand the current app’s data practices. For local removal steps or a prepared email request, open Account & Data Deletion."
          ],
          items: [],
          links: [],
        )
      ],
      requestForm: false,
      webUrl: 'https://hamimneo.github.io/necTeam-official/support/',
    )
  };

  PolicyModel getBundledPolicy(String slug) {
    final clean =
        slug.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
    return _bundledPolicies[clean] ??
        _bundledPolicies['privacy-policy'] ??
        const PolicyModel(
          key: 'privacy-policy',
          title: 'Privacy Policy',
          label: 'Your privacy',
          icon: 'shield',
          description: '',
          intro: '',
          sections: [],
          webUrl: '$_webBaseUrl/privacy-policy/',
        );
  }

  List<PolicyModel> getAllBundledPolicies() {
    return _bundledPolicies.values.toList();
  }

  Future<PolicyModel> getPolicy(String slug,
      {bool forceRefresh = false}) async {
    final clean =
        slug.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    if (!forceRefresh) {
      if (_memoryCache.containsKey(clean)) {
        return _memoryCache[clean]!;
      }

      final cached = await _loadFromPreferences(clean);
      if (cached != null) {
        _memoryCache[clean] = cached;
        return cached;
      }
    }

    try {
      final liveModel = await fetchLivePolicy(clean);
      if (liveModel != null) {
        _memoryCache[clean] = liveModel;
        await _saveToPreferences(clean, liveModel);
        return liveModel;
      }
    } catch (e) {
      debugPrint('Live policy fetch error for $clean: $e');
    }

    return _bundledPolicies[clean] ?? getBundledPolicy(clean);
  }

  Future<PolicyModel?> fetchLivePolicy(String slug) async {
    final clean =
        slug.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');

    try {
      final jsonMap = await _fetchJson(_apiEndpoint);
      if (jsonMap != null) {
        final policyData = jsonMap['/$clean'] ?? jsonMap[clean];
        if (policyData is Map<String, dynamic>) {
          return PolicyModel.fromJson(clean, policyData);
        }
      }
    } catch (e) {
      debugPrint('JSON API fetch failed, trying HTML fallback: $e');
    }

    try {
      final html = await _fetchHtml('$_webBaseUrl/$clean/');
      if (html != null && html.isNotEmpty) {
        final parsed = _parsePolicyFromHtml(clean, html);
        if (parsed != null) {
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('HTML fetch fallback failed: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> _fetchJson(String url) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
    return null;
  }

  Future<String?> _fetchHtml(String url) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'text/html');
      final response = await request.close();
      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
    return null;
  }

  PolicyModel? _parsePolicyFromHtml(String slug, String html) {
    try {
      final titleMatch =
          RegExp(r'<h1>(.*?)</h1>', dotAll: true).firstMatch(html);
      final title = titleMatch != null ? _cleanHtml(titleMatch.group(1)!) : '';

      final descMatch =
          RegExp(r'<p class="policy-description">(.*?)</p>', dotAll: true)
              .firstMatch(html);
      final description =
          descMatch != null ? _cleanHtml(descMatch.group(1)!) : '';

      final introMatch =
          RegExp(r'<div class="policy-intro">(.*?)</div', dotAll: true)
              .firstMatch(html);
      final intro = introMatch != null ? _cleanHtml(introMatch.group(1)!) : '';

      final sectionRegex = RegExp(
          r'<section id="section-\d+"[^>]*>(.*?)</section>',
          dotAll: true);
      final List<PolicySection> sections = [];

      for (final match in sectionRegex.allMatches(html)) {
        final secContent = match.group(1) ?? '';
        final sTitleMatch = RegExp(r'<h2>(.*?)</h2>').firstMatch(secContent);
        final sTitle =
            sTitleMatch != null ? _cleanHtml(sTitleMatch.group(1)!) : '';

        final paragraphs = <String>[];
        for (final pMatch
            in RegExp(r'<p>(.*?)</p>', dotAll: true).allMatches(secContent)) {
          final text = _cleanHtml(pMatch.group(1)!);
          if (text.isNotEmpty) paragraphs.add(text);
        }

        final items = <String>[];
        for (final liMatch
            in RegExp(r'<li>(.*?)</li>', dotAll: true).allMatches(secContent)) {
          final text = _cleanHtml(liMatch.group(1)!);
          if (text.isNotEmpty) items.add(text);
        }

        final links = <PolicyLink>[];
        for (final aMatch
            in RegExp(r'<a href="(.*?)"[^>]*>(.*?)</a>', dotAll: true)
                .allMatches(secContent)) {
          final href = aMatch.group(1) ?? '';
          final label = _cleanHtml(aMatch.group(2) ?? '');
          if (href.isNotEmpty && label.isNotEmpty) {
            links.add(PolicyLink(label: label, href: href));
          }
        }

        if (sTitle.isNotEmpty || paragraphs.isNotEmpty) {
          sections.add(PolicySection(
            title: sTitle,
            paragraphs: paragraphs,
            items: items,
            links: links,
          ));
        }
      }

      if (title.isNotEmpty) {
        final bundled = getBundledPolicy(slug);
        return PolicyModel(
          key: slug,
          title: title,
          label: bundled.label,
          icon: bundled.icon,
          description:
              description.isNotEmpty ? description : bundled.description,
          intro: intro.isNotEmpty ? intro : bundled.intro,
          sections: sections.isNotEmpty ? sections : bundled.sections,
          requestForm: bundled.requestForm,
          webUrl: '$_webBaseUrl/$slug/',
        );
      }
    } catch (e) {
      debugPrint('HTML parse error: $e');
    }
    return null;
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Future<PolicyModel?> _loadFromPreferences(String slug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('nec_policy_$slug');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return PolicyModel.fromJson(slug, map);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveToPreferences(String slug, PolicyModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nec_policy_$slug', jsonEncode(model.toJson()));
    } catch (_) {}
  }
}
