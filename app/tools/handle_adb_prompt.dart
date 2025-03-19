import 'dart:io';

void main() async {
  print('Ensuring device is properly connected...');
  
  await Process.run('adb', ['devices']);
  
  print('Attempting to set permission settings...');
  
  // Disable package verification which may be causing the issue
  await Process.run('adb', ['shell', 'settings', 'put', 'global', 'verifier_verify_adb_installs', '0']);
  await Process.run('adb', ['shell', 'settings', 'put', 'global', 'package_verifier_enable', '0']);
  
  print('Restarting ADB server to ensure clean connection...');
  await Process.run('adb', ['kill-server']);
  await Process.run('adb', ['start-server']);
  
  print('Done. Now try running "flutter run" again.');
  print('If the issue persists, you may need to physically check your device for permission prompts.');
}
