// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_sleep_logging_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postSleepLoggingControllerHash() =>
    r'0c2af2c73022ac6c6365e00a71ae2f967295efbc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PostSleepLoggingController
    extends BuildlessAutoDisposeAsyncNotifier<PostSleepLog> {
  late final String sleepDataId;

  FutureOr<PostSleepLog> build(String sleepDataId);
}

/// See also [PostSleepLoggingController].
@ProviderFor(PostSleepLoggingController)
const postSleepLoggingControllerProvider = PostSleepLoggingControllerFamily();

/// See also [PostSleepLoggingController].
class PostSleepLoggingControllerFamily
    extends Family<AsyncValue<PostSleepLog>> {
  /// See also [PostSleepLoggingController].
  const PostSleepLoggingControllerFamily();

  /// See also [PostSleepLoggingController].
  PostSleepLoggingControllerProvider call(String sleepDataId) {
    return PostSleepLoggingControllerProvider(sleepDataId);
  }

  @override
  PostSleepLoggingControllerProvider getProviderOverride(
    covariant PostSleepLoggingControllerProvider provider,
  ) {
    return call(provider.sleepDataId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postSleepLoggingControllerProvider';
}

/// See also [PostSleepLoggingController].
class PostSleepLoggingControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          PostSleepLoggingController,
          PostSleepLog
        > {
  /// See also [PostSleepLoggingController].
  PostSleepLoggingControllerProvider(String sleepDataId)
    : this._internal(
        () => PostSleepLoggingController()..sleepDataId = sleepDataId,
        from: postSleepLoggingControllerProvider,
        name: r'postSleepLoggingControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postSleepLoggingControllerHash,
        dependencies: PostSleepLoggingControllerFamily._dependencies,
        allTransitiveDependencies:
            PostSleepLoggingControllerFamily._allTransitiveDependencies,
        sleepDataId: sleepDataId,
      );

  PostSleepLoggingControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sleepDataId,
  }) : super.internal();

  final String sleepDataId;

  @override
  FutureOr<PostSleepLog> runNotifierBuild(
    covariant PostSleepLoggingController notifier,
  ) {
    return notifier.build(sleepDataId);
  }

  @override
  Override overrideWith(PostSleepLoggingController Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostSleepLoggingControllerProvider._internal(
        () => create()..sleepDataId = sleepDataId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sleepDataId: sleepDataId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    PostSleepLoggingController,
    PostSleepLog
  >
  createElement() {
    return _PostSleepLoggingControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostSleepLoggingControllerProvider &&
        other.sleepDataId == sleepDataId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sleepDataId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostSleepLoggingControllerRef
    on AutoDisposeAsyncNotifierProviderRef<PostSleepLog> {
  /// The parameter `sleepDataId` of this provider.
  String get sleepDataId;
}

class _PostSleepLoggingControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          PostSleepLoggingController,
          PostSleepLog
        >
    with PostSleepLoggingControllerRef {
  _PostSleepLoggingControllerProviderElement(super.provider);

  @override
  String get sleepDataId =>
      (origin as PostSleepLoggingControllerProvider).sleepDataId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
