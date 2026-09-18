final class RemoteUser {
  const RemoteUser({required this.id, required this.name, required this.email});

  factory RemoteUser.fromJson(Map<String, Object?> json) => RemoteUser(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
    email: _requiredString(json, 'email'),
  );

  final String id;
  final String name;
  final String email;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'email': email,
  };
}

final class RemoteSession {
  const RemoteSession({required this.accessToken, required this.user});

  factory RemoteSession.fromJson(Map<String, Object?> json) {
    final rawUser = json['user'];
    if (rawUser is! Map<String, Object?>) {
      throw const FormatException('Remote session user is invalid.');
    }
    return RemoteSession(
      accessToken: _requiredString(json, 'accessToken'),
      user: RemoteUser.fromJson(rawUser),
    );
  }

  final String accessToken;
  final RemoteUser user;

  Map<String, Object?> toJson() => <String, Object?>{
    'accessToken': accessToken,
    'user': user.toJson(),
  };
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Remote session field $key is invalid.');
  }
  return value;
}
