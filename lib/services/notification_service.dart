import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  // Stream seguro para notificaciones
  Stream<List<Map<String, dynamic>>> get notificationsStream {
    final user = _supabase.auth.currentUser;
    
    // Si el usuario es nulo (arranque de la app), devolvemos un stream vacío
    // Esto evita la pantalla blanca por el error 'Null check operator'
    if (user == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .map((maps) => maps.reversed.toList());
  }

  Future<void> markAsRead(int id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
