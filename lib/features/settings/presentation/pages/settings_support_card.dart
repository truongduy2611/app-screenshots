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
  bool _isLoading = true;
  bool _isAvailable = false;
  String? _error;

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
          _isLoading = false;
          _error = 'Store is not available.';
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
          _isLoading = false;
          _error = response.error!.message;
        });
      }
      return;
    }

    if (response.productDetails.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _productDetails = response.productDetails.first;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _isLoading = false;
          _error = 'Product not found.';
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
    if (!_isAvailable ||
        _error != null ||
        (_isLoading && _productDetails == null)) {
      // Return an empty box if store is unavailable, error occurred, or still loading initially
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      color: widget.isDark
          ? widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _buyConsumable,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Symbols.favorite_rounded,
                  color: widget.theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.supportTheDeveloper,
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.supportTheDeveloperDescription(
                        _productDetails?.price ?? "",
                      ),
                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                        color: widget.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Symbols.chevron_right_rounded,
                color: widget.theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
