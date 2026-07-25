import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_settings.dart';
import '../services/scan_repository.dart';
import '../theme/app_theme.dart';

/// App configuration: identity, AI backend toggle, and sync.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final repo = context.watch<ScanRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _GroupLabel('Identity'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Display name'),
              subtitle: Text(settings.author),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _editText(
                context,
                title: 'Display name',
                initial: settings.author,
                onSave: settings.setAuthor,
              ),
            ),
          ),
          const _GroupLabel('AI analysis'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_outlined),
                  title: const Text('Use real vision backend'),
                  subtitle: Text(settings.useRealBackend
                      ? 'Live analysis via your server'
                      : 'Demo mode — realistic sample results'),
                  value: settings.useRealBackend,
                  onChanged: settings.setUseRealBackend,
                ),
                if (settings.useRealBackend)
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Backend URL'),
                    subtitle: Text(settings.backendUrl),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _editText(
                      context,
                      title: 'Backend URL',
                      initial: settings.backendUrl,
                      hint: 'https://api.your-domain.com',
                      onSave: settings.setBackendUrl,
                    ),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'The app POSTs photos to {backend}/analyze and expects a JSON '
              'result. See README for the schema.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
          const _GroupLabel('Sync'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Auto-sync when online'),
                  value: settings.autoSync,
                  onChanged: settings.setAutoSync,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Sync now'),
                  subtitle: Text('${repo.pendingSync} scan(s) pending'),
                  onTap: () async {
                    final n = await repo.syncNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(n > 0
                                ? 'Synced $n scan(s).'
                                : 'Nothing synced — offline or up to date.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const _GroupLabel('About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('NdauSight AI'),
              subtitle: Text(
                  'v0.1.0 · Prototype. Mineral estimates are indicative only — '
                  'always confirm with XRF or laboratory assay.'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    String? hint,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) await onSave(result);
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted)),
    );
  }
}
