import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscriptions_provider.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الاشتراكات'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.credit_card),    text: 'الخطة'),
              Tab(icon: Icon(Icons.people),          text: 'الأعضاء'),
              Tab(icon: Icon(Icons.bar_chart),       text: 'الاستخدام'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlanTab(),
            _MembersTab(),
            _UsageTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Plan ───────────────────────────────────────────────
class _PlanTab extends ConsumerWidget {
  const _PlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub   = ref.watch(subscriptionProvider);
    final plans = ref.watch(plansProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(subscriptionProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current subscription card
            sub.when(
              loading: () => const _LoadingCard(),
              error:   (e, _) => _ErrorCard('$e'),
              data:    (s) => s != null ? _CurrentSubCard(sub: s) : const _NoSubCard(),
            ),
            const SizedBox(height: 24),
            Text('خطط الاشتراك',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            plans.when(
              loading: () => const _LoadingCard(),
              error:   (e, _) => _ErrorCard('$e'),
              data: (list) => Column(
                children: list.map((p) => _PlanCard(
                  plan: p,
                  currentPlanId: sub.value?.planId,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentSubCard extends StatelessWidget {
  final Subscription sub;
  const _CurrentSubCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final color = sub.status == 'active' ? Colors.green : Colors.orange;
    final statusLabel = {
      'active':   'نشط ✅',
      'past_due': 'متأخر الدفع ⚠️',
      'cancelled':'ملغي ❌',
    }[sub.status] ?? sub.status;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('اشتراكك الحالي',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(sub.planName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)),
            if (sub.priceMonthly > 0)
              Text('\$${sub.priceMonthly}/شهر',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            if (sub.currentPeriodEnd != null) ...[
              const SizedBox(height: 4),
              Text(
                'ينتهي: ${sub.currentPeriodEnd!.day}/${sub.currentPeriodEnd!.month}/${sub.currentPeriodEnd!.year}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 12),
              ),
            ],
            if (sub.cancelAtPeriodEnd) ...[
              const SizedBox(height: 4),
              const Text('⚠️ سيُلغى في نهاية الفترة',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              _LimitBadge('Leads',   sub.maxLeads),
              _LimitBadge('أعضاء',  sub.maxUsers),
              _LimitBadge('مصادر',  sub.maxSources),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LimitBadge extends StatelessWidget {
  final String label;
  final int value;
  const _LimitBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12)),
    child: Text(
      '$label: ${value == -1 ? "∞" : value}',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

class _NoSubCard extends StatelessWidget {
  const _NoSubCard();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16),
      child: Text('لا يوجد اشتراك نشط',
          style: Theme.of(context).textTheme.bodyLarge)),
  );
}

class _PlanCard extends ConsumerWidget {
  final SubscriptionPlan plan;
  final String? currentPlanId;
  const _PlanCard({required this.plan, this.currentPlanId});

  static const _featureLabels = {
    'leads':          '✅ إدارة Leads',
    'manual_dispatch':'✅ إرسال يدوي',
    'webhooks':       '✅ Webhooks',
    'auto_dispatch':  '✅ إرسال تلقائي',
    'analytics':      '✅ تقارير متقدمة',
    'whatsapp':       '✅ واتساب',
    'all':            '✅ جميع المميزات',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = currentPlanId == plan.id;
    final isFree    = plan.id == 'free';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: isCurrent ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!isFree)
                  Text('\$${plan.priceMonthly}/شهر • \$${plan.priceYearly}/سنة',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary,
                          fontSize: 13, fontWeight: FontWeight.bold))
                else
                  const Text('مجاناً', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('خطتك الحالية',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _FeatureBadge(Icons.people,
                  'Leads: ${plan.maxLeads == -1 ? "∞" : plan.maxLeads}'),
              _FeatureBadge(Icons.person,
                  'أعضاء: ${plan.maxUsers == -1 ? "∞" : plan.maxUsers}'),
              _FeatureBadge(Icons.link,
                  'مصادر: ${plan.maxSources == -1 ? "∞" : plan.maxSources}'),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: plan.features.map((f) =>
              Text(_featureLabels[f] ?? f,
                  style: const TextStyle(fontSize: 12)),
            ).toList()),
            if (!isCurrent && !isFree) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => _upgrade(context, plan, 'monthly'),
                  child: const Text('شهري'),
                )),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(
                  onPressed: () => _upgrade(context, plan, 'yearly'),
                  child: const Text('سنوي (وفر 17%)'),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  void _upgrade(BuildContext ctx, SubscriptionPlan plan, String cycle) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('الترقية إلى ${plan.name}'),
      content: Text(
        cycle == 'yearly'
          ? 'السعر: \$${plan.priceYearly}/سنة (توفر \$${(plan.priceMonthly*12 - plan.priceYearly).toStringAsFixed(0)})'
          : 'السعر: \$${plan.priceMonthly}/شهر',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('سيتم ربط بوابة الدفع قريباً')),
            );
          },
          child: const Text('ترقية'),
        ),
      ],
    ));
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: Colors.grey),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ]);
}

// ── Tab 2: Members ────────────────────────────────────────────
class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  static const _roleLabels = {'admin': 'مدير', 'agent': 'موظف', 'viewer': 'مشاهد'};
  static const _roleColors = {
    'admin':  Colors.purple, 'agent': Colors.blue, 'viewer': Colors.grey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final sub = ref.watch(subscriptionProvider).value;
    final maxUsers = sub?.maxUsers ?? 2;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMember(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة عضو'),
      ),
      body: Column(
        children: [
          // Usage bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: members.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => Row(children: [
                Text('${list.length} من ${maxUsers == -1 ? "∞" : maxUsers} عضو',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                if (maxUsers != -1) Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: list.length / maxUsers,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        list.length >= maxUsers ? Colors.red : Colors.blue),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (list) => list.isEmpty
              ? const Center(child: Text('لا يوجد أعضاء'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final roleColor = _roleColors[m.role] ?? Colors.grey;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.15),
                          child: Text(
                            m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.email, style: const TextStyle(fontSize: 12)),
                            if (m.lastLogin != null)
                              Text(
                                'آخر دخول: ${m.lastLogin!.day}/${m.lastLogin!.month}/${m.lastLogin!.year}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: roleColor.withOpacity(0.3)),
                            ),
                            child: Text(_roleLabels[m.role] ?? m.role,
                                style: TextStyle(fontSize: 11, color: roleColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) => _handleMemberAction(context, ref, v, m),
                            itemBuilder: (_) => [
                              if (m.role != 'admin')
                                const PopupMenuItem(value: 'make_admin',
                                    child: Text('ترقية لمدير')),
                              if (m.role != 'agent')
                                const PopupMenuItem(value: 'make_agent',
                                    child: Text('تعيين كموظف')),
                              PopupMenuItem(
                                value: m.isActive ? 'deactivate' : 'activate',
                                child: Text(m.isActive ? 'إيقاف' : 'تفعيل'),
                              ),
                            ],
                          ),
                        ]),
                        isThreeLine: m.lastLogin != null,
                      ),
                    );
                  },
                ),
          )),
        ],
      ),
    );
  }

  void _handleMemberAction(BuildContext ctx, WidgetRef ref, String action, OrgMember m) async {
    final Map<String, dynamic> data = switch (action) {
      'make_admin'  => {'role': 'admin'},
      'make_agent'  => {'role': 'agent'},
      'deactivate'  => {'is_active': false},
      'activate'    => {'is_active': true},
      _             => {},
    };
    if (data.isNotEmpty) {
      await ref.read(membersProvider.notifier).updateMember(m.id, data);
    }
  }

  void _showAddMember(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      builder: (_) => _AddMemberSheet(ref: ref),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddMemberSheet({required this.ref});
  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  String _role = 'agent';
  bool _loading = false;

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      left: 16, right: 16, top: 16,
    ),
    child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إضافة عضو جديد', style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextFormField(controller: _name,
          decoration: const InputDecoration(labelText: 'الاسم *', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'البريد الإلكتروني *', border: OutlineInputBorder()),
          validator: (v) => v?.contains('@') != true ? 'بريد غير صحيح' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _role,
        decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'admin',  child: Text('مدير')),
          DropdownMenuItem(value: 'agent',  child: Text('موظف')),
          DropdownMenuItem(value: 'viewer', child: Text('مشاهد فقط')),
        ],
        onChanged: (v) => setState(() => _role = v!),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _submit,
        icon: _loading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.send),
        label: const Text('إضافة'),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
      const SizedBox(height: 8),
    ])),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.ref.read(membersProvider.notifier).addMember({
        'full_name': _name.text, 'email': _email.text, 'role': _role,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _loading = false); }
  }
}

// ── Tab 3: Usage ──────────────────────────────────────────────
class _UsageTab extends ConsumerWidget {
  const _UsageTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);
    final sub = ref.watch(subscriptionProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(usageProvider);
        ref.invalidate(subscriptionProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('استخدام الحساب',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            usage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (u) => Column(children: [
                _UsageBar(
                  label: 'العملاء (Leads)',
                  icon: Icons.people,
                  current: u['leads'] as int,
                  max: sub?.maxLeads ?? 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _UsageBar(
                  label: 'أعضاء الفريق',
                  icon: Icons.person,
                  current: u['members'] as int,
                  max: sub?.maxUsers ?? 2,
                  color: Colors.purple,
                ),
                const SizedBox(height: 12),
                _UsageBar(
                  label: 'مصادر العملاء',
                  icon: Icons.ads_click,
                  current: u['sources'] as int,
                  max: sub?.maxSources ?? 1,
                  color: Colors.orange,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // Billing history placeholder
            Text('سجل المدفوعات',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('لا توجد مدفوعات حتى الآن',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('سيظهر سجل المدفوعات بعد الترقية',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int current, max;
  final Color color;

  const _UsageBar({
    required this.label, required this.icon,
    required this.current, required this.max, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max == -1 ? 0.0 : (current / max).clamp(0.0, 1.0);
    final isUnlimited = max == -1;
    final isNearLimit = !isUnlimited && pct >= 0.8;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Text(
                isUnlimited ? '$current / ∞' : '$current / $max',
                style: TextStyle(
                    color: isNearLimit ? Colors.red : color,
                    fontWeight: FontWeight.bold),
              ),
            ]),
            const SizedBox(height: 8),
            if (!isUnlimited) ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                    isNearLimit ? Colors.red : color),
              ),
            ) else Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.3), color]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (isNearLimit) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                const Text('اقتربت من الحد الأقصى — فكّر بالترقية',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) =>
      const Card(child: Padding(padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())));
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.red.shade50,
    child: Padding(padding: const EdgeInsets.all(16),
        child: Text('خطأ: $message', style: const TextStyle(color: Colors.red))));
}
