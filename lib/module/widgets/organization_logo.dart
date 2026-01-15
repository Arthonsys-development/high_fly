import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/data/models/response_model/organization_response_model.dart';
import 'package:highfly/module/providers/organization_provider.dart';
// Conditional import for web image widget
import '../screens/visitors/web_image_widget.dart' if (dart.library.io) '../screens/visitors/web_image_widget_stub.dart';

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

    final borderRadiusValue = borderRadius != null
        ? (borderRadius as BorderRadius?)?.topLeft.x ?? 0
        : null;

    // For web, use WebImageWidget if we have at least one dimension
    // If only one dimension is provided, use it for both (maintains aspect ratio with BoxFit.contain)
    final networkImage = kIsWeb && (width != null || height != null)
        ? WebImageWidget(
            imageUrl: logoUrl,
            width: width ?? height ?? 100, // Use provided width, or height, or default
            height: height ?? width ?? 100, // Use provided height, or width, or default
            borderRadius: borderRadiusValue,
            fit: fit ?? BoxFit.contain,
          )
        : Image.network(
            logoUrl,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder,
          );

    if (borderRadius != null && !kIsWeb) {
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
    return image;// Icon(Icons.landscape, color: AppColors.primaryColor);
  }
}

