import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Optimized list view with built-in ad insertion and performance optimizations
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? adBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;
  final Widget? emptyWidget;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.adBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.emptyWidget,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    // Calculate total items including ads
    final totalItems = _calculateTotalItems();

    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        return _buildOptimizedItem(context, index);
      },
    );
  }

  /// Calculate total items including ads
  int _calculateTotalItems() {
    if (adBuilder == null) return items.length;

    // Add ads after every adInterval items, but not after the last item
    final adCount = (items.length / AppConfig.adInterval).floor();
    return items.length + adCount;
  }

  /// Build optimized item with ad insertion logic
  Widget _buildOptimizedItem(BuildContext context, int index) {
    if (adBuilder == null) {
      // No ads, direct item building
      return _OptimizedListItem(
        key: ValueKey('item_${items[index].hashCode}'),
        child: itemBuilder(context, items[index], index),
      );
    }

    // Calculate position with ads
    final adsBefore = (index / (AppConfig.adInterval + 1)).floor();
    final adjustedIndex = index - adsBefore;

    // Check if this position should be an ad
    if ((index + 1) % (AppConfig.adInterval + 1) == 0 && index < _calculateTotalItems() - 1) {
      return _OptimizedListItem(
        key: ValueKey('ad_$index'),
        child: adBuilder!(context),
      );
    }

    // Ensure we don't exceed the items list
    if (adjustedIndex >= items.length) {
      return const SizedBox.shrink();
    }

    return _OptimizedListItem(
      key: ValueKey('item_${items[adjustedIndex].hashCode}'),
      child: itemBuilder(context, items[adjustedIndex], adjustedIndex),
    );
  }
}

/// Optimized list item wrapper with performance enhancements
class _OptimizedListItem extends StatelessWidget {
  final Widget child;

  const _OptimizedListItem({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Sliver version of optimized list view
class OptimizedSliverList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? adBuilder;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const OptimizedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.adBuilder,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Calculate total items including ads
    final totalItems = adBuilder == null 
        ? items.length 
        : items.length + (items.length / AppConfig.adInterval).floor();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (adBuilder == null) {
            return _OptimizedListItem(
              key: ValueKey('item_${items[index].hashCode}'),
              child: itemBuilder(context, items[index], index),
            );
          }

          // Calculate position with ads
          final adsBefore = (index / (AppConfig.adInterval + 1)).floor();
          final adjustedIndex = index - adsBefore;

          // Check if this position should be an ad
          if ((index + 1) % (AppConfig.adInterval + 1) == 0 && index < totalItems - 1) {
            return _OptimizedListItem(
              key: ValueKey('ad_$index'),
              child: adBuilder!(context),
            );
          }

          // Ensure we don't exceed the items list
          if (adjustedIndex >= items.length) {
            return const SizedBox.shrink();
          }

          return _OptimizedListItem(
            key: ValueKey('item_${items[adjustedIndex].hashCode}'),
            child: itemBuilder(context, items[adjustedIndex], adjustedIndex),
          );
        },
        childCount: totalItems,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
      ),
    );
  }
}

/// Performance-optimized grid view
class OptimizedGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;
  final Widget? emptyWidget;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        return _OptimizedListItem(
          key: ValueKey('grid_item_${items[index].hashCode}'),
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Memoized widget for expensive computations
class MemoizedWidget extends StatelessWidget {
  final Widget Function() builder;
  final List<Object?> dependencies;
  
  const MemoizedWidget({
    super.key,
    required this.builder,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return _MemoizedWidgetHelper(
      builder: builder,
      dependencies: dependencies,
    );
  }
}

class _MemoizedWidgetHelper extends StatefulWidget {
  final Widget Function() builder;
  final List<Object?> dependencies;

  const _MemoizedWidgetHelper({
    required this.builder,
    required this.dependencies,
  });

  @override
  State<_MemoizedWidgetHelper> createState() => _MemoizedWidgetHelperState();
}

class _MemoizedWidgetHelperState extends State<_MemoizedWidgetHelper> {
  Widget? _cachedWidget;
  List<Object?>? _lastDependencies;

  @override
  Widget build(BuildContext context) {
    // Check if dependencies have changed
    if (_cachedWidget == null || !_dependenciesEqual(_lastDependencies, widget.dependencies)) {
      _cachedWidget = widget.builder();
      _lastDependencies = List.from(widget.dependencies);
    }
    
    return _cachedWidget!;
  }

  bool _dependenciesEqual(List<Object?>? a, List<Object?> b) {
    if (a == null) return false;
    if (a.length != b.length) return false;
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
}
