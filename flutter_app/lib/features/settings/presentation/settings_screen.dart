import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';

final leadSourcesProvider = FutureProvider<List<Map>>((ref) async {
  final r = await ref.read(apiClientProvider).get('/settings/lead-sources');
  return List<Map>.from(r.data['data']);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(children: [
        _header(context, 'الحساب'),
        ListTile(
          leading: CircleAvatar(child: Text(user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?')),
          title: Text(user?.fullName ?? ''),
          subtitle: Text(user?.email ?? ''),
        ),
        const Divider(),
        _header(context, 'مصادر العملاء'),
        ListTile(
          leading: const Icon(Icons.ads_click),
          title: const Text('Webhook URLs'),
          subtitle: const Text('ربط Facebook, TikTok, Google'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SourcesScreen())),
        ),
        const Divider(),
        _header(context, 'التطبيق'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('الإصدار'),
          trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          onTap: () => _logout(context, ref),
        ),
        const SizedBox(height: 32),
        Center(child: Text('LeadBridge Iraq © 2024', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _header(BuildContext ctx, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(title, style: TextStyle(color: Theme.of(ctx).colorScheme.primary,
        fontWeight: FontWeight.bold, fontSize: 13)),
  );

  void _logout(BuildContext ctx, WidgetRef ref) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('تسجيل الخروج'),
      content: const Text('هل تريد الخروج؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { Navigator.pop(ctx); ref.read(authStateProvider.notifier).logout(); },
          child: const Text('خروج'),
        ),
      ],
    ));
  }
}

class _SourcesScreen extends ConsumerWidget {
  const _SourcesScreen();

  static const _apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api');

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final sources = ref.watch(leadSourcesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مصادر العملاء')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(ctx, ref),
        icon: const Icon(Icons.add), label: const Text('مصدر جديد'),
      ),
      body: sources.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد مصادر مضافة'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final s = list[i];
                final url = '$_apiUrl/webhooks/${s['type']}/${s['webhook_secret']}';
                return Card(margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.link, color: Colors.blue),
                    title: Text(s['name'] ?? ''),
                    subtitle: Text(s['type'] ?? ''),
                    children: [Padding(padding: const EdgeInsets.all(12), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Webhook URL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Expanded(child: Text(url, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                            IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('تم النسخ ✓')));
                            }),
                          ])),
                        TextButton.icon(
                          onPressed: () async {
                            await ref.read(apiClientProvider).delete('/settings/lead-sources/${s['id']}');
                            ref.invalidate(leadSourcesProvider);
                          },
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ))],
                  ));
              }),
      ),
    );
  }

  void _showAdd(BuildContext ctx, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String type = 'facebook';
    showModalBottomSheet(context: ctx, builder: (c) => StatefulBuilder(
      builder: (c, setState) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('مصدر جديد', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المصدر', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: type,
            decoration: const InputDecoration(labelText: 'المنصة', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'facebook', child: Text('Facebook Ads')),
              DropdownMenuItem(value: 'tiktok',   child: Text('TikTok Ads')),
              DropdownMenuItem(value: 'google',   child: Text('Google Ads')),
              DropdownMenuItem(value: 'manual',   child: Text('يدوي')),
            ],
            onChanged: (v) => setState(() => type = v!)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              await ref.read(apiClientProvider).post('/settings/lead-sources', data: {'name': nameCtrl.text, 'type': type});
              ref.invalidate(leadSourcesProvider);
              if (c.mounted) Navigator.pop(c);
            },
            icon: const Icon(Icons.save), label: const Text('حفظ'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ]),
      ),
    ));
  }
}
