import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Artist's Alley", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "A social network for artists to share their work, follow each other, and interact.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Developed by:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("• Fernando Ruiz Murciano", style: TextStyle(fontSize: 14)),
                  Text("• Lucía Jiménez Morales", style: TextStyle(fontSize: 14)),
                  SizedBox(height: 8),
                  Text("For Albor Croft Jerez", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text("View licenses", style: TextStyle(color: Color(0xFF6C63FF)))),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.white))),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Account"),
          _buildSettingItem(Icons.person_outline, "Edit Profile", () => Navigator.pushNamed(context, '/edit_profile')),
          _buildSettingItem(Icons.lock_outline, "Change Password", () {}),
          const Divider(color: Color(0xFF1E1E1E)),
          _buildSectionHeader("App"),
          _buildSettingItem(Icons.notifications_none, "Notifications", () {}),
          _buildSettingItem(Icons.palette_outlined, "Theme", () {}, subtitle: "System default"),
          const Divider(color: Color(0xFF1E1E1E)),
          _buildSectionHeader("About"),
          _buildSettingItem(Icons.info_outline, "About Artist's Alley", () => _showAboutDialog(context)),
          _buildSettingItem(Icons.security, "Privacy Policy", () {}),
          _buildSettingItem(Icons.description_outlined, "Terms of Service", () {}),
          const Divider(color: Color(0xFF1E1E1E)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          const SizedBox(height: 20),
          const Center(child: Text("Artist's Alley v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
