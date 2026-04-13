import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  // Stream para notificaciones en tiempo real
  Stream<List<Map<String, dynamic>>> get notificationsStream {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  // Marcar como leída (opcional)
  Future<void> markAsRead(int id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
