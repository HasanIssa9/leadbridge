import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leads_provider.dart';

const _statusColors = {'new': Colors.orange, 'assigned': Colors.blue, 'in_delivery': Colors.purple, 'delivered': Colors.green, 'cancelled': Colors.red};
const _statusLabels = {'new': 'جديد', 'assigned': 'معين', 'in_delivery': 'في التوصيل', 'delivered': 'مُسلَّم', 'cancelled': 'ملغي'};

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});
  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final _search = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _addLead(context)),
      ]),
      body: Column(children: [
        // Search
        Padding(padding: const EdgeInsets.all(8), child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'بحث...', prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear),
              onPressed: () { _search.clear(); ref.read(leadsProvider.notifier).setSearch(''); }) : null,
          ),
          onChanged: (v) => ref.read(leadsProvider.notifier).setSearch(v),
        )),
        // Filters
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _chip('الكل', null), _chip('جديد', 'new'), _chip('توصيل', 'in_delivery'),
            _chip('مُسلَّم', 'delivered'), _chip('ملغي', 'cancelled'),
          ]),
        ),
        // Stats
        if (state.stats != null) _StatsRow(stats: state.stats!),
        // List
        Expanded(child: state.isLoading && state.leads.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.leads.isEmpty
            ? const Center(child: Text('لا توجد عملاء'))
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200)
                    ref.read(leadsProvider.notifier).loadMore();
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.leads.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == state.leads.length)
                      return const Center(child: Padding(padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator()));
                    final lead = state.leads[i];
                    return _LeadTile(lead: lead,
                      onDispatch: () => _dispatch(lead),
                      onDelete: () => ref.read(leadsProvider.notifier).deleteLead(lead.id));
                  },
                ),
              )),
      ]),
    );
  }

  Widget _chip(String label, String? status) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ActionChip(label: Text(label), onPressed: () => ref.read(leadsProvider.notifier).setStatus(status)),
  );

  Future<void> _dispatch(Lead lead) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('إرسال للتوصيل'),
      content: Text('هل تريد إرسال "${lead.fullName}" للتوصيل؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إرسال')),
      ],
    ));
    if (ok == true) {
      try {
        await ref.read(leadsProvider.notifier).dispatch(lead.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الإرسال ✓'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _addLead(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (_) => _AddLeadSheet());
  }
}

class _StatsRow extends StatelessWidget {
  final Map stats;
  const _StatsRow({required this.stats});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(children: [
      _chip('الكل', int.parse(stats['total'].toString()), Colors.blue),
      _chip('جديد', int.parse(stats['new_count'].toString()), Colors.orange),
      _chip('توصيل', int.parse(stats['in_delivery_count'].toString()), Colors.purple),
      _chip('مُسلَّم', int.parse(stats['delivered_count'].toString()), Colors.green),
      _chip('اليوم', int.parse(stats['today_count'].toString()), Colors.teal),
    ]),
  );
  Widget _chip(String l, int v, Color c) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withOpacity(0.3))),
    child: Text('$l: $v', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
  );
}

class _LeadTile extends StatelessWidget {
  final Lead lead; final VoidCallback onDispatch, onDelete;
  const _LeadTile({required this.lead, required this.onDispatch, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[lead.status] ?? Colors.grey;
    final label = _statusLabels[lead.status] ?? lead.status;
    return Card(margin: const EdgeInsets.only(bottom: 6), child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.15),
          child: Text(lead.fullName.isNotEmpty ? lead.fullName[0] : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lead.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(lead.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          if (lead.province != null) Text(lead.province!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if (lead.product != null) Text(lead.product!, style: TextStyle(color: Colors.blue[400], fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (lead.status == 'new' || lead.status == 'assigned')
              IconButton(icon: const Icon(Icons.local_shipping, size: 20), color: Colors.purple,
                onPressed: onDispatch, tooltip: 'إرسال للتوصيل'),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: Colors.red,
              onPressed: onDelete, tooltip: 'حذف'),
          ]),
        ]),
      ]),
    ));
  }
}

class _AddLeadSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddLeadSheet> createState() => _AddLeadSheetState();
}
class _AddLeadSheetState extends ConsumerState<_AddLeadSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _product = TextEditingController();
  final _notes = TextEditingController();
  String? _province;
  bool _loading = false;

  static const _provinces = ['بغداد','البصرة','نينوى','أربيل','النجف','كربلاء','الأنبار','ديالى','كركوك','صلاح الدين','واسط','ميسان','ذي قار','المثنى','القادسية','بابل','السليمانية','دهوك'];

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom, left: 16, right: 16, top: 16),
    child: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة عميل', style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم *'),
        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'الهاتف *'),
        keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _province,
        decoration: const InputDecoration(labelText: 'المحافظة'),
        items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (v) => setState(() => _province = v)),
      const SizedBox(height: 12),
      TextFormField(controller: _product, decoration: const InputDecoration(labelText: 'المنتج')),
      const SizedBox(height: 12),
      TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'ملاحظات'), maxLines: 2),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _submit,
        icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
        label: const Text('حفظ'),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
      const SizedBox(height: 8),
    ]))),
  );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(leadsProvider.notifier).addLead({
        'full_name': _name.text, 'phone': _phone.text,
        'province': _province, 'product': _product.text.isEmpty ? null : _product.text,
        'notes': _notes.text.isEmpty ? null : _notes.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }
}
