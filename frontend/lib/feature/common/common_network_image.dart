import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/constants/images.dart';

class CommonNetworkWidget extends StatelessWidget {
  const CommonNetworkWidget({
    super.key,
    this.width,
    this.height,
    this.errorWidget,
    this.fit,
    required this.imageUrl,
  });

  final double? width;
  final double? height;
  final String imageUrl;
  final Widget? errorWidget;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: errorWidget ??
            SvgPicture.asset(
              AppIcons.errorPlaceholderImage,
              width: width,
              height: height,
              fit: fit ?? BoxFit.fill,
            ),
      );
    }
    return Container(
      height: height,
      width: width,
      constraints: BoxConstraints(
        maxHeight: height ?? 195,
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit ?? BoxFit.fill,
        errorWidget: (context, url, error) =>
        errorWidget ??
            SvgPicture.asset(
              AppIcons.errorPlaceholderImage,
              width: width,
              height: height,
              fit: fit ?? BoxFit.fill,
            ),
        placeholder: (_, __) => SizedBox(
          width: width,
          height: height,
          child: SvgPicture.asset(
            AppIcons.errorPlaceholderImage,
            fit: fit ?? BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
