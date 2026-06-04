import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Lead {
  final String id, fullName, phone, status;
  final String? phone2, province, city, product, notes, sourceName, trackingNumber;
  final DateTime createdAt;
  Lead({required this.id, required this.fullName, required this.phone,
      required this.status, this.phone2, this.province, this.city,
      this.product, this.notes, this.sourceName, this.trackingNumber,
      required this.createdAt});
  factory Lead.fromJson(Map<String, dynamic> j) => Lead(
    id: j['id'], fullName: j['full_name'], phone: j['phone'],
    status: j['status'] ?? 'new', phone2: j['phone2'], province: j['province'],
    city: j['city'], product: j['product'], notes: j['notes'],
    sourceName: j['source_name'], trackingNumber: j['tracking_number'],
    createdAt: DateTime.parse(j['created_at']),
  );
}

class LeadsState {
  final List<Lead> leads;
  final Map? stats;
  final bool isLoading, hasMore;
  final int page;
  final String? status, search;
  const LeadsState({this.leads=const[], this.stats, this.isLoading=false,
      this.hasMore=true, this.page=1, this.status, this.search});
  LeadsState copyWith({List<Lead>? leads, Map? stats, bool? isLoading,
      bool? hasMore, int? page, String? status, String? search}) =>
      LeadsState(leads: leads??this.leads, stats: stats??this.stats,
          isLoading: isLoading??this.isLoading, hasMore: hasMore??this.hasMore,
          page: page??this.page, status: status??this.status, search: search??this.search);
}

class LeadsNotifier extends Notifier<LeadsState> {
  @override
  LeadsState build() { load(); return const LeadsState(isLoading: true); }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{'page': page, 'limit': 20};
      if (state.status != null) params['status'] = state.status;
      if (state.search != null && state.search!.isNotEmpty) params['search'] = state.search;
      final leadsResp = await _api.get('/leads', params: params);
      final newLeads = (leadsResp.data['data'] as List).map((e) => Lead.fromJson(e)).toList();
      Map? newStats = state.stats;
      if (refresh || state.stats == null) {
        final statsResp = await _api.get('/leads/stats');
        newStats = statsResp.data['data'] as Map?;
      }
      state = state.copyWith(
        leads: refresh ? newLeads : [...state.leads, ...newLeads],
        stats: newStats,
        isLoading: false, hasMore: newLeads.length == 20, page: page + 1,
      );
    } catch (_) { state = state.copyWith(isLoading: false); }
  }

  Future<void> loadMore() async { if (state.hasMore && !state.isLoading) await load(); }
  Future<void> setStatus(String? s) async { state = state.copyWith(status: s, page: 1, leads: [], hasMore: true); await load(refresh: true); }
  Future<void> setSearch(String? s) async { state = state.copyWith(search: s, page: 1, leads: [], hasMore: true); await load(refresh: true); }

  Future<void> addLead(Map<String, dynamic> data) async {
    await _api.post('/leads', data: data);
    await load(refresh: true);
  }

  Future<void> dispatch(String leadId) async {
    await _api.post('/delivery/dispatch/$leadId');
    await load(refresh: true);
  }

  Future<void> deleteLead(String id) async {
    await _api.delete('/leads/$id');
    await load(refresh: true);
  }
}

final leadsProvider = NotifierProvider<LeadsNotifier, LeadsState>(LeadsNotifier.new);
