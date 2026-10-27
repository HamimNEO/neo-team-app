import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../../features/auth/presentation/controllers/auth_session.dart';
import '../../features/team/presentation/widgets/agreement_pdf_viewer.dart';

class ProtectedDocumentScreen extends StatefulWidget {
  const ProtectedDocumentScreen(
      {super.key, required this.url, required this.title});

  final String url, title;

  @override
  State<ProtectedDocumentScreen> createState() =>
      _ProtectedDocumentScreenState();
}

class _ProtectedDocumentScreenState extends State<ProtectedDocumentScreen> {
  final _session = AuthSession.instance;
  late final _api = ApiClient(
      baseUrl: () => AppConfig.apiBaseUrl,
      accessToken: () => _session.accessToken,
      onUnauthorized: _session.invalidate);
  late Future<Uint8List> _document;

  @override
  void initState() {
    super.initState();
    _document = _load();
  }

  Future<Uint8List> _load() async {
    final token = _session.accessToken;
    final bytes = await _api.downloadDocument(widget.url, token: token);
    if (token != _session.accessToken) {
      throw const FormatException('Your account changed.');
    }
    return bytes;
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
      future: _document,
      builder: (context, state) {
        if (state.hasData) {
          return AgreementPdfViewer(title: widget.title, bytes: state.data);
        }
        return Scaffold(
            appBar: AppBar(title: Text(widget.title)),
            body: Center(
                child: state.hasError
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                state.error is FormatException
                                    ? (state.error as FormatException).message
                                    : 'Document unavailable.',
                                textAlign: TextAlign.center)),
                        TextButton(
                            onPressed: () =>
                                setState(() => _document = _load()),
                            child: const Text('Retry'))
                      ])
                    : const CircularProgressIndicator()));
      });
}
