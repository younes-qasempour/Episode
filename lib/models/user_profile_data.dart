import 'dart:convert';
import 'package:flutter/material.dart';

/// Available avatar theme accent colors.
const List<Color> avatarAccentColors = [
  Color(0xFF6366F1), // Indigo / Violet
  Color(0xFFEC4899), // Pink / Rose
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber / Sunset
  Color(0xFF06B6D4), // Cyan / Ocean
  Color(0xFF8B5CF6), // Purple
];

/// Editable personal profile metadata for customization.
class UserProfileData {
  final String displayName;
  final String bio;
  final String favoriteQuote;
  final int avatarColorIndex;

  const UserProfileData({
    this.displayName = 'Episode Tracker',
    this.bio = 'Tracking my favorite anime, manga, and series.',
    this.favoriteQuote = '',
    this.avatarColorIndex = 0,
  });

  Color get avatarColor {
    if (avatarColorIndex < 0 || avatarColorIndex >= avatarAccentColors.length) {
      return avatarAccentColors[0];
    }
    return avatarAccentColors[avatarColorIndex];
  }

  UserProfileData copyWith({
    String? displayName,
    String? bio,
    String? favoriteQuote,
    int? avatarColorIndex,
  }) {
    return UserProfileData(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      favoriteQuote: favoriteQuote ?? this.favoriteQuote,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'bio': bio,
      'favoriteQuote': favoriteQuote,
      'avatarColorIndex': avatarColorIndex,
    };
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      displayName: json['displayName']?.toString() ?? 'Episode Tracker',
      bio: json['bio']?.toString() ??
          'Tracking my favorite anime, manga, and series.',
      favoriteQuote: json['favoriteQuote']?.toString() ?? '',
      avatarColorIndex: json['avatarColorIndex'] is int
          ? json['avatarColorIndex'] as int
          : 0,
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserProfileData.decode(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfileData.fromJson(decoded);
    } catch (_) {
      return const UserProfileData();
    }
  }
}
