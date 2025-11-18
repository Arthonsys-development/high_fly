import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/data/models/response_model/organization_response_model.dart';
import 'package:highfly/module/providers/organization_provider.dart';

class OrganizationLogo extends ConsumerWidget {
  const OrganizationLogo({
    super.key,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationState = ref.watch(organizationProvider);
    return organizationState.when(
      data: (organization) => _buildLogo(organization),
      loading: () => _buildPlaceholder(),
      error: (_, __) => _buildPlaceholder(),
    );
  }

  Widget _buildLogo(Organization? organization) {
    final placeholder = _buildPlaceholder();
    final logoUrl = organization?.logoUrl;

    if (logoUrl == null || logoUrl.isEmpty) {
      return placeholder;
    }

    final networkImage = Image.network(
      logoUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      errorBuilder: (_, __, ___) => placeholder,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: networkImage,
      );
    }

    return networkImage;
  }

  Widget _buildPlaceholder() {
    final image = Image.asset(
      ImageAssets.highFlyLogo,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return Icon(Icons.landscape, color: AppColors.primaryColor);
    return image;
  }
}

