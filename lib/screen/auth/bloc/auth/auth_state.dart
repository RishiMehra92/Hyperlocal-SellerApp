import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class ProfileDeleteSuccess extends AuthState {
  final String message;
  const ProfileDeleteSuccess({this.message = "Success"});
  @override
  List<Object?> get props => [message];
}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess({this.message = "Success"});
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class AuthOTPSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String message;

  const AuthOTPSent({
    required this.verificationId,
    required this.phoneNumber,
    this.message = "OTP Sent Successfully",
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthOTPVerified extends AuthState {
  final String message;

  const AuthOTPVerified({this.message = "OTP Verified Successfully"});

  @override
  List<Object?> get props => [message];
}

class AuthSignUpSuccess extends AuthState {
  final String message;
  const AuthSignUpSuccess({this.message = "Registration Successful"});

  @override
  List<Object?> get props => [message];
}

class AuthSignUpOTPSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String message;

  const AuthSignUpOTPSent({
    required this.verificationId,
    required this.phoneNumber,
    this.message = "OTP Sent Successfully",
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber, message];
}

class AuthOTPResent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String message;

  const AuthOTPResent({
    required this.verificationId,
    required this.phoneNumber,
    this.message = "OTP Resent Successfully",
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber, message];
}

class AuthSignUpOTPResent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String message;

  const AuthSignUpOTPResent({
    required this.verificationId,
    required this.phoneNumber,
    this.message = "OTP Resent Successfully",
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber, message];
}
