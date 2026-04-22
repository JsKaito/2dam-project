import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> get notificationsStream {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((event) async {
          if (event.isEmpty) return [];
          
          // 1. Obtenemos todos los sender_id únicos
          final senderIds = event.map((n) => n['sender_id'] as String).toSet().toList();

          // 2. Cargamos TODOS los perfiles de golpe en una sola consulta
          final profilesData = await _supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .inFilter('id', senderIds);

          // 3. Creamos un mapa rápido para acceso instantáneo
          final Map<String, dynamic> profilesMap = {
            for (var p in profilesData) p['id']: p
          };

          // 4. Enlazamos los datos en memoria sin esperas adicionales
          return event.map((notif) {
            return {
              ...notif,
              'sender_profile': profilesMap[notif['sender_id']],
            };
          }).toList();
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', userId);
  }
}
