import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../leads/providers/leads_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(authStateProvider).value;
    final state = ref.watch(leadsProvider);
    final stats = state.stats;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، ${user?.fullName.split(' ').first ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(leadsProvider.notifier).load(refresh: true)),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(leadsProvider.notifier).load(refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // KPI Grid
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _KpiCard('الإجمالي',  int.parse(stats['total'].toString()),  Icons.people,       Colors.blue),
                      _KpiCard('اليوم',     int.parse(stats['today_count'].toString()), Icons.today,   Colors.teal),
                      _KpiCard('في التوصيل',int.parse(stats['in_delivery_count'].toString()), Icons.local_shipping, Colors.purple),
                      _KpiCard('مُسلَّم',   int.parse(stats['delivered_count'].toString()), Icons.check_circle, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('توزيع الحالات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(height: 200, child: _StatusChart(stats: stats)),
                  const SizedBox(height: 24),
                  _StatusBars(stats: stats),
                ]),
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label; final int value; final IconData icon; final Color color;
  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Icon(icon, color: color, size: 20),
        ]),
        Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      ],
    )),
  );
}

class _StatusChart extends StatelessWidget {
  final Map stats;
  const _StatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (double.parse(stats['new_count'].toString()),         Colors.orange, 'جديد'),
      (double.parse(stats['in_delivery_count'].toString()), Colors.purple, 'توصيل'),
      (double.parse(stats['delivered_count'].toString()),   Colors.green,  'مُسلَّم'),
      (double.parse(stats['cancelled_count'].toString()),   Colors.red,    'ملغي'),
    ].where((s) => s.$1 > 0).map((s) =>
      PieChartSectionData(value: s.$1, color: s.$2, title: s.$3, radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
    ).toList();

    if (sections.isEmpty) return const Center(child: Text('لا توجد بيانات'));
    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2));
  }
}

class _StatusBars extends StatelessWidget {
  final Map stats;
  const _StatusBars({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = int.parse(stats['total'].toString());
    if (total == 0) return const SizedBox.shrink();
    final items = [
      ('جديد',        int.parse(stats['new_count'].toString()),         Colors.orange),
      ('في التوصيل',  int.parse(stats['in_delivery_count'].toString()), Colors.purple),
      ('مُسلَّم',     int.parse(stats['delivered_count'].toString()),   Colors.green),
      ('ملغي',        int.parse(stats['cancelled_count'].toString()),   Colors.red),
    ];
    return Column(children: items.map((e) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text(e.$1, style: const TextStyle(fontSize: 13))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: e.$2 / total,
            backgroundColor: e.$3.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(e.$3), minHeight: 10))),
        SizedBox(width: 36, child: Text('${e.$2}', textAlign: TextAlign.end,
          style: TextStyle(fontWeight: FontWeight.bold, color: e.$3))),
      ]),
    )).toList());
  }
}
