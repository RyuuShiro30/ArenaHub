import 'package:flutter/material.dart';

final adminNameNotifier  = ValueNotifier<String>('Admin');
final adminRoleNotifier  = ValueNotifier<String>('Administrator');
final ValueNotifier<String?> adminPhotoNotifier = ValueNotifier(null);