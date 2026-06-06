import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────

class Subscription {
  final String id, orgId, planId, status, billingCycle, planName;
  final double priceMonthly;
  final int maxLeads, maxUsers, maxSources;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  const Subscription({
    required this.id, required this.orgId, required this.planId,
    required this.status, required this.billingCycle, required this.planName,
    required this.priceMonthly, required this.maxLeads,
    required this.maxUsers, required this.maxSources,
    this.currentPeriodEnd, this.cancelAtPeriodEnd = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    id: j['id'] ?? '', orgId: j['org_id'] ?? '', planId: j['plan_id'] ?? '',
    status: j['status'] ?? 'active', billingCycle: j['billing_cycle'] ?? 'monthly',
    planName: j['plan_name'] ?? '',
    priceMonthly: double.tryParse(j['price_monthly']?.toString() ?? '0') ?? 0,
    maxLeads: int.tryParse(j['max_leads']?.toString() ?? '0') ?? 0,
    maxUsers: int.tryParse(j['max_users']?.toString() ?? '0') ?? 0,
    maxSources: int.tryParse(j['max_sources']?.toString() ?? '0') ?? 0,
    currentPeriodEnd: j['current_period_end'] != null
        ? DateTime.tryParse(j['current_period_end'].toString()) : null,
    cancelAtPeriodEnd: j['cancel_at_period_end'] ?? false,
  );
}

class SubscriptionPlan {
  final String id, name;
  final double priceMonthly, priceYearly;
  final int maxLeads, maxUsers, maxSources;
  final List<String> features;

  const SubscriptionPlan({
    required this.id, required this.name,
    required this.priceMonthly, required this.priceYearly,
    required this.maxLeads, required this.maxUsers, required this.maxSources,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
    id: j['id'] ?? '', name: j['name'] ?? '',
    priceMonthly: double.tryParse(j['price_monthly']?.toString() ?? '0') ?? 0,
    priceYearly:  double.tryParse(j['price_yearly']?.toString()  ?? '0') ?? 0,
    maxLeads:   int.tryParse(j['max_leads']?.toString()   ?? '0') ?? 0,
    maxUsers:   int.tryParse(j['max_users']?.toString()   ?? '0') ?? 0,
    maxSources: int.tryParse(j['max_sources']?.toString() ?? '0') ?? 0,
    features: List<String>.from(j['features'] ?? []),
  );
}

class OrgMember {
  final String id, fullName, email, role;
  final bool isActive;
  final DateTime? lastLogin;

  const OrgMember({
    required this.id, required this.fullName, required this.email,
    required this.role, required this.isActive, this.lastLogin,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
    id: j['id'] ?? '', fullName: j['full_name'] ?? '',
    email: j['email'] ?? '', role: j['role'] ?? 'agent',
    isActive: j['is_active'] ?? true,
    lastLogin: j['last_login'] != null
        ? DateTime.tryParse(j['last_login'].toString()) : null,
  );
}

// ── Providers ─────────────────────────────────────────────────

final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  try {
    final r = await ref.read(apiClientProvider).get('/settings/subscription');
    final data = r.data['data'];
    if (data == null) return null;
    return Subscription.fromJson(data as Map<String, dynamic>);
  } catch (_) { return null; }
});

final plansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final r = await ref.read(apiClientProvider).get('/settings/plans');
  return (r.data['data'] as List)
      .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MembersNotifier extends AsyncNotifier<List<OrgMember>> {
  @override
  Future<List<OrgMember>> build() async {
    final r = await ref.read(apiClientProvider).get('/settings/team');
    return (r.data['data'] as List)
        .map((e) => OrgMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addMember(Map<String, dynamic> data) async {
    await ref.read(apiClientProvider).post('/settings/team', data: data);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    final members = state.value ?? [];
    final current = members.where((m) => m.id == id).firstOrNull;
    final merged = {
      'role': current?.role ?? 'agent',
      'is_active': current?.isActive ?? true,
      ...data,
    };
    await ref.read(apiClientProvider).put('/settings/team/$id', data: merged);
    ref.invalidateSelf();
    await future;
  }
}

final membersProvider =
    AsyncNotifierProvider<MembersNotifier, List<OrgMember>>(MembersNotifier.new);

final usageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final results = await Future.wait([
    api.get('/leads/stats'),
    api.get('/settings/team'),
    api.get('/settings/lead-sources'),
  ]);
  return {
    'leads':   int.tryParse(results[0].data['data']['total']?.toString() ?? '0') ?? 0,
    'members': (results[1].data['data'] as List).length,
    'sources': (results[2].data['data'] as List).length,
  };
});
