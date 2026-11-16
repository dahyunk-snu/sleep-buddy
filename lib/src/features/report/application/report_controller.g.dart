// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reportHash() => r'83857ae092e8f9805361f935d04894c3e318eca1';

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

/// See also [report].
@ProviderFor(report)
const reportProvider = ReportFamily();

/// See also [report].
class ReportFamily extends Family<AsyncValue<SleepReport>> {
  /// See also [report].
  const ReportFamily();

  /// See also [report].
  ReportProvider call(
    String childId,
    ReportType reportType,
    DateTime selectedDate,
  ) {
    return ReportProvider(childId, reportType, selectedDate);
  }

  @override
  ReportProvider getProviderOverride(covariant ReportProvider provider) {
    return call(provider.childId, provider.reportType, provider.selectedDate);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'reportProvider';
}

/// See also [report].
class ReportProvider extends AutoDisposeFutureProvider<SleepReport> {
  /// See also [report].
  ReportProvider(String childId, ReportType reportType, DateTime selectedDate)
    : this._internal(
        (ref) => report(ref as ReportRef, childId, reportType, selectedDate),
        from: reportProvider,
        name: r'reportProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$reportHash,
        dependencies: ReportFamily._dependencies,
        allTransitiveDependencies: ReportFamily._allTransitiveDependencies,
        childId: childId,
        reportType: reportType,
        selectedDate: selectedDate,
      );

  ReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.childId,
    required this.reportType,
    required this.selectedDate,
  }) : super.internal();

  final String childId;
  final ReportType reportType;
  final DateTime selectedDate;

  @override
  Override overrideWith(
    FutureOr<SleepReport> Function(ReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportProvider._internal(
        (ref) => create(ref as ReportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        childId: childId,
        reportType: reportType,
        selectedDate: selectedDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SleepReport> createElement() {
    return _ReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportProvider &&
        other.childId == childId &&
        other.reportType == reportType &&
        other.selectedDate == selectedDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, childId.hashCode);
    hash = _SystemHash.combine(hash, reportType.hashCode);
    hash = _SystemHash.combine(hash, selectedDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReportRef on AutoDisposeFutureProviderRef<SleepReport> {
  /// The parameter `childId` of this provider.
  String get childId;

  /// The parameter `reportType` of this provider.
  ReportType get reportType;

  /// The parameter `selectedDate` of this provider.
  DateTime get selectedDate;
}

class _ReportProviderElement
    extends AutoDisposeFutureProviderElement<SleepReport>
    with ReportRef {
  _ReportProviderElement(super.provider);

  @override
  String get childId => (origin as ReportProvider).childId;
  @override
  ReportType get reportType => (origin as ReportProvider).reportType;
  @override
  DateTime get selectedDate => (origin as ReportProvider).selectedDate;
}

String _$reportControllerHash() => r'b0d2684b3b03bf9dfd55afebcc206c641c19fdce';

/// See also [ReportController].
@ProviderFor(ReportController)
final reportControllerProvider =
    AutoDisposeNotifierProvider<ReportController, ReportScreenState>.internal(
      ReportController.new,
      name: r'reportControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReportController = AutoDisposeNotifier<ReportScreenState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
