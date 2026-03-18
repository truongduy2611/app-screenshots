import 'package:equatable/equatable.dart';

/// ASC API key credentials for JWT authentication.
class AscCredentials extends Equatable {
  final String keyId;
  final String issuerId;
  final String? privateKeyContent;

  const AscCredentials({
    required this.keyId,
    required this.issuerId,
    this.privateKeyContent,
  });

  bool get isValid =>
      keyId.isNotEmpty &&
      issuerId.isNotEmpty &&
      privateKeyContent != null &&
      privateKeyContent!.isNotEmpty;

  @override
  List<Object?> get props => [keyId, issuerId, privateKeyContent];
}
