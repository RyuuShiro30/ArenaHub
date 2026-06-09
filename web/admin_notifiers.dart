import 'package:flutter/material.dart';

// Notifier untuk menyimpan data nama admin secara global
final ValueNotifier<String> adminNameNotifier = ValueNotifier<String>('Admin');
// Notifier untuk menyimpan data role/level admin secara global
final ValueNotifier<String> adminRoleNotifier = ValueNotifier<String>('Administrator');
// Notifier untuk menyimpan URL foto profil admin secara global (bisa null)
final ValueNotifier<String?> adminPhotoNotifier = ValueNotifier<String?>(null);
// Notifier untuk manajemen state indeks halaman/navigasi admin secara global
final ValueNotifier<int> adminCurrentIndexNotifier = ValueNotifier<int>(0);