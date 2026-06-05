// Demo data shown when backend is not connected
const demoLeads = [
  {'id': '1', 'full_name': 'أحمد محمد', 'phone': '07701234567', 'province': 'بغداد', 'product': 'جهاز لابتوب', 'status': 'new', 'created_at': '2026-06-05T10:00:00Z'},
  {'id': '2', 'full_name': 'سارة علي', 'phone': '07809876543', 'province': 'البصرة', 'product': 'موبايل سامسونج', 'status': 'in_delivery', 'created_at': '2026-06-04T09:00:00Z'},
  {'id': '3', 'full_name': 'علي حسن', 'phone': '07716543210', 'province': 'نينوى', 'product': 'ساعة ذكية', 'status': 'delivered', 'created_at': '2026-06-03T08:00:00Z'},
  {'id': '4', 'full_name': 'فاطمة كريم', 'phone': '07801122334', 'province': 'أربيل', 'product': 'سماعات بلوتوث', 'status': 'new', 'created_at': '2026-06-05T11:00:00Z'},
  {'id': '5', 'full_name': 'محمود عبدالله', 'phone': '07715566778', 'province': 'النجف', 'product': 'تابلت iPad', 'status': 'assigned', 'created_at': '2026-06-04T14:00:00Z'},
];

const demoStats = {
  'total': 5, 'new_count': 2, 'assigned_count': 1,
  'in_delivery_count': 1, 'delivered_count': 1,
  'cancelled_count': 0, 'today_count': 2, 'week_count': 5,
};

const demoOrders = [
  {'id': '1', 'full_name': 'سارة علي', 'phone': '07809876543', 'province': 'البصرة', 'product': 'موبايل سامسونج', 'status': 'in_transit', 'company_name': 'Labeeb', 'tracking_number': 'LB-2024-001', 'created_at': '2026-06-04T09:00:00Z'},
];

const demoCompanies = [
  {'id': '1', 'name': 'Labeeb', 'api_type': 'labeeb', 'is_active': true, 'supported_provinces': ['بغداد', 'البصرة', 'النجف']},
  {'id': '2', 'name': 'Fetchr Iraq', 'api_type': 'fetchr', 'is_active': true, 'supported_provinces': ['بغداد', 'أربيل', 'السليمانية']},
];
