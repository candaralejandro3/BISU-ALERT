import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/api_service.dart';
import '../theme/app_colors.dart';

/// Bottom bar or tile to inspect, test, and configure the MySQL backend connection.
class ServerConnectionBar extends StatefulWidget {
  const ServerConnectionBar({super.key});

  @override
  State<ServerConnectionBar> createState() => _ServerConnectionBarState();
}

class _ServerConnectionBarState extends State<ServerConnectionBar> {
  bool? _isConnected;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;
    setState(() => _isTesting = true);
    final bool ok = await ApiService().testConnection();
    if (!mounted) return;
    setState(() {
      _isConnected = ok;
      _isTesting = false;
    });
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ServerConfigDialog(onSaved: () {
          _checkStatus();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;

    final Color statusColor = _isTesting
        ? Colors.orange
        : (_isConnected == true ? Colors.green : Colors.grey.shade600);

    final String statusText = _isTesting
        ? 'Checking...'
        : (_isConnected == true ? 'Connected' : 'Tap to test/configure');

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: InkWell(
        onTap: () => _openSettingsDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'MySQL API: ',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        statusText,
                        style: textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ApiService().baseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ServerConfigDialog extends StatefulWidget {
  const _ServerConfigDialog({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<_ServerConfigDialog> {
  late final TextEditingController _urlController;
  bool _testing = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService().baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final String original = ApiService().baseUrl;
    ApiService().setCustomBaseUrl(_urlController.text.trim());
    final bool ok = await ApiService().testConnection();

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testSuccess = ok;
      if (ok) {
        _testMessage = 'Connection successful! MySQL database is responding.';
      } else {
        ApiService().setCustomBaseUrl(original);
        _testMessage =
            'Cannot reach the server. Ensure WAMP/PHP is running on port 80/8000.';
      }
    });
  }

  void _save() {
    final String clean = _urlController.text.trim();
    ApiService().setCustomBaseUrl(clean);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('custom_api_base_url', clean);
    });
    widget.onSaved();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL updated and saved.')),
    );
  }

  void _resetDefault() {
    final String defaultUrl = ApiService.defaultBaseUrl;
    _urlController.text = defaultUrl;
    ApiService().setCustomBaseUrl(null);
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('custom_api_base_url');
    });
    setState(() {
      _testMessage = null;
      _testSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('MySQL Server Setup'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend API address where WAMP / MySQL is running:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://localhost/bisu-alert/backend/api',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt, size: 16),
                  label: const Text('Test Connection'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _resetDefault,
                  child: const Text('Reset'),
                ),
              ],
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? Colors.green : AppColors.sos)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _testMessage!,
                  style: TextStyle(
                    color: _testSuccess == true ? Colors.green.shade800 : AppColors.sos,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Quick Tip:\n'
              '• On PC/Windows/Web: http://localhost/bisu-alert/backend/api\n'
              '• On Android Emulator: http://10.0.2.2/bisu-alert/backend/api\n'
              '• On Physical Phone (Same Wi-Fi): http://192.168.94.90/bisu-alert/backend/api\n'
              '• PHP Built-in Server: http://localhost:8000/backend/api',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
