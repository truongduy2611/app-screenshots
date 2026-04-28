part of 'settings_page.dart';

class _SupportMeCard extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;

  const _SupportMeCard({required this.isDark, required this.theme});

  @override
  State<_SupportMeCard> createState() => _SupportMeCardState();
}

class _SupportMeCardState extends State<_SupportMeCard> {
  final InAppPurchase _iap = InAppPurchase.instance;
  ProductDetails? _productDetails;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initStoreInfo();
  }

  Future<void> _initStoreInfo() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
        });
      }
      return;
    }

    const Set<String> kIds = <String>{'support_app_screenshots'};
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );

    if (response.error != null) {
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
        });
      }
      return;
    }

    if (response.productDetails.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _productDetails = response.productDetails.first;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
        });
      }
    }
  }

  void _buyConsumable() {
    if (_productDetails != null) {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: _productDetails!,
      );
      _iap.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    final borderRadius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.colorScheme.primary.withValues(
                alpha: widget.isDark ? 0.12 : 0.08,
              ),
              widget.theme.colorScheme.tertiary.withValues(
                alpha: widget.isDark ? 0.1 : 0.06,
              ),
            ],
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: widget.theme.colorScheme.primary.withValues(
              alpha: widget.isDark ? 0.2 : 0.12,
            ),
          ),
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: _buyConsumable,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Symbols.favorite_rounded,
                  size: 24,
                  color: widget.theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.supportTheDeveloper,
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.supportTheDeveloperDescription(
                          _productDetails?.price ?? "",
                        ),
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  size: 18,
                  color: widget.theme.colorScheme.onSurface.withValues(
                    alpha: 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
