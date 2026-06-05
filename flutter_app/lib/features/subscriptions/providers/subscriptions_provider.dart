import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ── Models ─────────────────────────────────────────────────────
class SubscriptionPlan {
  final String id, name;
  final double priceMonthly, priceYearly;
  final int maxLeads, maxUsers, maxSources;
  final List<String> features;

  SubscriptionPlan({
    required this.id, required this.name,
    required this.priceMonthly, required this.priceYearly,
    required this.maxLeads, required this.maxUsers, required this.maxSources,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
    id: j['id'], name: j['name'],
    priceMonthly: double.parse(j['price_monthly']?.toString() ?? '0'),
    priceYearly:  double.parse(j['price_yearly']?.toString() ?? '0'),
    maxLeads:   j['max_leads'] ?? 0,
    maxUsers:   j['max_users'] ?? 0,
    maxSources: j['max_sources'] ?? 0,
    features:   List<String>.from(j['features'] ?? []),
  );
}

class Subscription {
  final String planId, planName, status, billingCycle;
  final int maxLeads, maxUsers, maxSources;
  final double priceMonthly;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  Subscription({
    required this.planId, required this.planName,
    required this.status, required this.billingCycle,
    required this.maxLeads, required this.maxUsers, required this.maxSources,
    required this.priceMonthly,
    this.currentPeriodEnd, this.cancelAtPeriodEnd = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    planId:      j['plan_id'] ?? 'free',
    planName:    j['plan_name'] ?? 'مجاني',
    status:      j['status'] ?? 'active',
    billingCycle: j['billing_cycle'] ?? 'monthly',
    maxLeads:    j['max_leads'] ?? 100,
    maxUsers:    j['max_users'] ?? 2,
    maxSources:  j['max_sources'] ?? 1,
    priceMonthly: double.parse(j['price_monthly']?.toString() ?? '0'),
    currentPeriodEnd: j['current_period_end'] != null
        ? DateTime.tryParse(j['current_period_end']) : null,
    cancelAtPeriodEnd: j['cancel_at_period_end'] ?? false,
  );
}

class OrgMember {
  final String id, email, fullName, role;
  final bool isActive;
  final DateTime? lastLogin;

  OrgMember({
    required this.id, required this.email,
    required this.fullName, required this.role,
    required this.isActive, this.lastLogin,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
    id: j['id'], email: j['email'],
    fullName: j['full_name'] ?? '',
    role: j['role'] ?? 'agent',
    isActive: j['is_active'] ?? true,
    lastLogin: j['last_login'] != null ? DateTime.tryParse(j['last_login']) : null,
  );
}

// ── Providers ──────────────────────────────────────────────────
final subscriptionProvider = AsyncNotifierProvider<SubscriptionNotifier, Subscription?>(
  SubscriptionNotifier.new,
);

class SubscriptionNotifier extends AsyncNotifier<Subscription?> {
  @override
  Future<Subscription?> build() async {
    try {
      final r = await ref.read(apiClientProvider).get('/settings/subscription');
      return Subscription.fromJson(r.data['data']);
    } catch (_) { return null; }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final plansProvider = AsyncNotifierProvider<PlansNotifier, List<SubscriptionPlan>>(
  PlansNotifier.new,
);

class PlansNotifier extends AsyncNotifier<List<SubscriptionPlan>> {
  @override
  Future<List<SubscriptionPlan>> build() async {
    try {
      final r = await ref.read(apiClientProvider).get('/settings/plans');
      return (r.data['data'] as List).map((e) => SubscriptionPlan.fromJson(e)).toList();
    } catch (_) { return _defaultPlans(); }
  }

  List<SubscriptionPlan> _defaultPlans() => [
    SubscriptionPlan(id: 'free', name: 'مجاني', priceMonthly: 0, priceYearly: 0,
        maxLeads: 100, maxUsers: 2, maxSources: 1,
        features: ['leads', 'manual_dispatch']),
    SubscriptionPlan(id: 'pro', name: 'احترافي', priceMonthly: 29.99, priceYearly: 299,
        maxLeads: 5000, maxUsers: 10, maxSources: 5,
        features: ['leads', 'webhooks', 'auto_dispatch', 'analytics', 'whatsapp']),
    SubscriptionPlan(id: 'enterprise', name: 'مؤسسي', priceMonthly: 99.99, priceYearly: 999,
        maxLeads: -1, maxUsers: -1, maxSources: -1,
        features: ['all']),
  ];
}

final membersProvider = AsyncNotifierProvider<MembersNotifier, List<OrgMember>>(
  MembersNotifier.new,
);

class MembersNotifier extends AsyncNotifier<List<OrgMember>> {
  @override
  Future<List<OrgMember>> build() async {
    try {
      final r = await ref.read(apiClientProvider).get('/settings/team');
      return (r.data['data'] as List).map((e) => OrgMember.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  Future<void> addMember(Map<String, dynamic> data) async {
    await ref.read(apiClientProvider).post('/settings/team', data: data);
    ref.invalidateSelf();
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    await ref.read(apiClientProvider).put('/settings/team/$id', data: data);
    ref.invalidateSelf();
  }

  Future<void> removeMember(String id) async {
    await ref.read(apiClientProvider).put('/settings/team/$id', data: {'is_active': false});
    ref.invalidateSelf();
  }
}

// Usage stats
final usageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final [leadsR, membersR, sourcesR] = await Future.wait([
      ref.read(apiClientProvider).get('/leads/stats'),
      ref.read(apiClientProvider).get('/settings/team'),
      ref.read(apiClientProvider).get('/settings/lead-sources'),
    ]);
    return {
      'leads':   int.parse(leadsR.data['data']['total']?.toString() ?? '0'),
      'members': (membersR.data['data'] as List).length,
      'sources': (sourcesR.data['data'] as List).length,
    };
  } catch (_) { return {'leads': 0, 'members': 0, 'sources': 0}; }
});
