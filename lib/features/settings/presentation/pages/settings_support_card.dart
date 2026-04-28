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
    return AppListTile(
      leading: Icon(
        Symbols.favorite_rounded,
        size: 20,
        color: widget.theme.colorScheme.onSurface,
      ),
      title: Text(
        context.l10n.supportTheDeveloper,
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        context.l10n.supportTheDeveloperDescription(
          _productDetails?.price ?? "",
        ),
        style: widget.theme.textTheme.bodySmall?.copyWith(
          color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Icon(
        Symbols.chevron_right_rounded,
        size: 18,
        color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      onTap: _isAvailable ? _buyConsumable : null,
    );
  }
}
