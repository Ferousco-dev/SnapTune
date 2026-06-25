import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error']);
}

class ProcessingFailure extends Failure {
  const ProcessingFailure([super.message = 'Processing failed']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
