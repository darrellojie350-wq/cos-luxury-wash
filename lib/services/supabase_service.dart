import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../models/address.dart';

class AppConfig {
  // Inject at build time: flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://YOUR-PROJECT.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'YOUR-ANON-KEY');
}

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  static Future<void> init() async {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }

  Future<AuthResponse> signInEmail(String email, String password) =>
      client.auth.signInPassword(email: email, password: password);

  Future<AuthResponse> signUpEmail(String email, String password, {String? fullName, String? phone}) =>
      client.auth.signUp(email: email, password: password, data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      });

  Future<void> signOut() => client.auth.signOut();

  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    return await client.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client.from('profiles').upsert({...data, 'id': currentUser!.id});
  }

  Future<List<ServiceItem>> getServices() async {
    final res = await client.from('services').select().eq('is_active', true).order('sort');
    return (res as List).map((e) => ServiceItem.fromJson(e)).toList();
  }

  Future<List<AppAddress>> getAddresses() async {
    if (currentUser == null) return [];
    final res = await client.from('addresses').select().eq('user_id', currentUser!.id).order('is_default', ascending: false);
    return (res as List).map((e) => AppAddress.fromJson(e)).toList();
  }

  Future<void> addAddress(AppAddress a) async {
    await client.from('addresses').insert({...a.toJson(), 'user_id': currentUser!.id});
  }

  Future<List<WashOrder>> getOrders() async {
    if (currentUser == null) return [];
    final res = await client.from('orders').select('*, service:services(*)').eq('user_id', currentUser!.id).order('created_at', ascending: false);
    return (res as List).map((e) => WashOrder.fromJson(e)).toList();
  }

  Future<WashOrder> createOrder(WashOrder o) async {
    final res = await client.from('orders').insert({...o.toJson(), 'user_id': currentUser!.id}).select().single();
    return WashOrder.fromJson(res);
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? note}) async {
    await client.from('orders').update({'status': status}).eq('id', orderId);
    await client.from('order_status_history').insert({'order_id': orderId, 'status': status, if (note != null) 'note': note});
  }

  Stream<Map<String, dynamic>> orderStream(String orderId) =>
      client.from('orders').stream(primaryKey: ['id']).eq('id', orderId).map((e) => e.first);

  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    final res = await client.from('order_status_history').select().eq('order_id', orderId).order('created_at');
    return res as List<Map<String, dynamic>>;
  }

  Future<double> getWalletBalance() async {
    final p = await getProfile();
    return (p?['wallet_balance'] ?? 0).toDouble();
  }
}
