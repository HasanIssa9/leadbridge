import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final companiesProvider = FutureProvider<List<Map>>((ref) async {
  final r = await ref.read(apiClientProvider).get('/delivery/companies');
  return List<Map>.from(r.data['data']);
});

final ordersProvider = FutureProvider<List<Map>>((ref) async {
  final r = await ref.read(apiClientProvider).get('/delivery/orders');
  return List<Map>.from(r.data['data']);
});

class DeliveryScreen extends ConsumerWidget {
  const DeliveryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(title: const Text('التوصيل'), bottom: const TabBar(tabs: [
        Tab(icon: Icon(Icons.business), text: 'الشركات'),
        Tab(icon: Icon(Icons.list_alt), text: 'الطلبات'),
      ])),
      body: const TabBarView(children: [_CompaniesTab(), _OrdersTab()]),
    ));
  }
}

class _CompaniesTab extends ConsumerWidget {
  const _CompaniesTab();
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(ctx, ref),
        icon: const Icon(Icons.add), label: const Text('إضافة شركة'),
      ),
      body: companies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد شركات توصيل'))
          : ListView.builder(padding: const EdgeInsets.fromLTRB(12,12,12,80),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (c['is_active'] == true ? Colors.green : Colors.grey).withOpacity(0.2),
                      child: Icon(Icons.local_shipping,
                        color: c['is_active'] == true ? Colors.green : Colors.grey)),
                    title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c['api_type'] ?? 'manual'),
                    trailing: Icon(c['is_active'] == true ? Icons.check_circle : Icons.cancel,
                      color: c['is_active'] == true ? Colors.green : Colors.grey),
                  ));
              }),
      ),
    );
  }

  void _showAdd(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      builder: (_) => _AddCompanySheet(onAdd: (data) async {
        await ref.read(apiClientProvider).post('/delivery/companies', data: data);
        ref.invalidate(companiesProvider);
      }));
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  static const _colors = {'pending': Colors.orange, 'picked_up': Colors.blue, 'in_transit': Colors.purple, 'delivered': Colors.green, 'failed': Colors.red, 'returned': Colors.grey};
  static const _labels = {'pending': 'انتظار', 'picked_up': 'استُلم', 'in_transit': 'في الطريق', 'delivered': 'مُسلَّم', 'failed': 'فشل', 'returned': 'مُرتجع'};

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ordersProvider),
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) => list.isEmpty
          ? const Center(child: Text('لا توجد طلبات'))
          : ListView.builder(padding: const EdgeInsets.all(8), itemCount: list.length,
              itemBuilder: (_, i) {
                final o = list[i];
                final color = _colors[o['status']] ?? Colors.grey;
                return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(o['phone'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      if (o['province'] != null) Text(o['province'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      if (o['tracking_number'] != null)
                        Text('# ${o['tracking_number']}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3))),
                        child: Text(_labels[o['status']] ?? o['status'],
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
                      if (o['company_name'] != null)
                        Text(o['company_name'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ]),
                ));
              }),
      ),
    );
  }
}

class _AddCompanySheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;
  const _AddCompanySheet({required this.onAdd});
  @override
  State<_AddCompanySheet> createState() => _AddCompanySheetState();
}
class _AddCompanySheetState extends State<_AddCompanySheet> {
  final _name = TextEditingController();
  String _type = 'manual';
  bool _loading = false;

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة شركة توصيل', style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الشركة', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _type,
        decoration: const InputDecoration(labelText: 'نوع التكامل', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'manual', child: Text('يدوي')),
          DropdownMenuItem(value: 'labeeb', child: Text('Labeeb API')),
          DropdownMenuItem(value: 'fetchr',  child: Text('Fetchr API')),
          DropdownMenuItem(value: 'rest',    child: Text('REST مخصص')),
        ],
        onChanged: (v) => setState(() => _type = v!)),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : () async {
          if (_name.text.isEmpty) return;
          setState(() => _loading = true);
          await widget.onAdd({'name': _name.text, 'api_type': _type});
          if (mounted) Navigator.pop(context);
        },
        icon: const Icon(Icons.save), label: const Text('حفظ'),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
      const SizedBox(height: 8),
    ]),
  );
}
