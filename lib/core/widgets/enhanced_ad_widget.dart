import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../utils/responsive_utils.dart';

/// Enhanced Native Ad Widget with better visual integration
class EnhancedNativeAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final double? height;
  final bool showBorder;
  
  const EnhancedNativeAdWidget({
    super.key,
    this.margin,
    this.height,
    this.showBorder = true,
  });

  @override
  State<EnhancedNativeAdWidget> createState() => _EnhancedNativeAdWidgetState();
}

class _EnhancedNativeAdWidgetState extends State<EnhancedNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AppConfig.currentNativeAdUnitId,
      factoryId: 'adFactoryExample',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          debugPrint('✅ Native Ad loaded successfully');
          setState(() {
            _nativeAdIsLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Native Ad failed to load: ${error.message} (Code: ${error.code})');
          ad.dispose();
          setState(() {
            _isLoading = false;
          });
        },
        onAdClicked: (_) {
          debugPrint('📱 Native Ad clicked');
        },
        onAdImpression: (_) {
          debugPrint('👁️ Native Ad impression recorded');
        },
      ),
    );

    try {
      _nativeAd!.load();
    } catch (e) {
      debugPrint('❌ Error loading native ad: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    // Show ad if loaded
    if (_nativeAdIsLoaded && _nativeAd != null) {
      return _buildAdContainer(context);
    }

    // Don't show anything if ad failed to load
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: widget.height ?? 120.0,
      margin: widget.margin ?? context.responsiveHorizontalPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        border: widget.showBorder
            ? Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              )
            : null,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildAdContainer(BuildContext context) {
    return Container(
      height: widget.height ?? 120.0,
      margin: widget.margin ?? context.responsiveHorizontalPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        border: widget.showBorder
            ? Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}

/// Enhanced Banner Ad Widget with better responsive design
class EnhancedBannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry? margin;
  final bool showInEmptyState;
  
  const EnhancedBannerAdWidget({
    super.key,
    this.margin,
    this.showInEmptyState = false,
  });

  @override
  State<EnhancedBannerAdWidget> createState() => _EnhancedBannerAdWidgetState();
}

class _EnhancedBannerAdWidgetState extends State<EnhancedBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() async {
    // Get screen width for responsive ad sizing
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    // Get an AnchoredAdaptiveBannerAdSize
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            screenWidth.truncate());

    if (size == null) {
      debugPrint('❌ Unable to get banner ad size');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AppConfig.currentBannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner Ad loaded successfully');
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('❌ Banner Ad failed to load: ${err.message} (Code: ${err.code})');
          ad.dispose();
          setState(() {
            _isLoading = false;
          });
        },
        onAdClicked: (_) {
          debugPrint('📱 Banner Ad clicked');
        },
        onAdImpression: (_) {
          debugPrint('👁️ Banner Ad impression recorded');
        },
      ),
    );

    try {
      _bannerAd!.load();
    } catch (e) {
      debugPrint('❌ Error loading banner ad: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    // Show ad if loaded
    if (_bannerAd != null && _isLoaded) {
      return _buildAdContainer(context);
    }

    // Don't show anything if ad failed to load
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60.0,
      margin: widget.margin ?? context.responsiveHorizontalPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8.0),
            Text(
              'Loading ad...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdContainer(BuildContext context) {
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: widget.margin ?? EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

/// Ad separator for lists - makes ads feel more integrated
class AdSeparator extends StatelessWidget {
  const AdSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'SPONSORED',
              style: TextStyle(
                fontSize: 10.0,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline ad widget for specific placement scenarios
class InlineAdWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const InlineAdWidget({
    super.key,
    this.title = 'Sponsored Content',
    this.icon = Icons.campaign_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: context.responsiveHorizontalPadding,
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(context.responsiveBorderRadius()),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const AdSeparator(),
          SizedBox(height: 8.0),
          const EnhancedNativeAdWidget(
            margin: EdgeInsets.zero,
            showBorder: false,
          ),
        ],
      ),
    );
  }
}
