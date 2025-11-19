import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/constants/colors.dart';

class CircularButton extends StatefulWidget {
  final String? imagePath;
  final ImageType imageType;
  final String buttonText;
  final double? width;
  final double? height;
  final Color textColor;
  final Color buttonColor;
  final Color borderColor;
  final Future<void> Function()? onPressed;

  const CircularButton({
    this.imagePath,
    required this.buttonText,
    this.width,
    this.height,
    this.textColor = AppColors.primaryColor,
    this.imageType = ImageType.image,
    this.buttonColor = AppColors.primaryBackgroundColor,
    this.borderColor = AppColors.primaryColor,
    this.onPressed,
    super.key,
  });

  @override
  State<CircularButton> createState() => _CircularButtonState();
}

class _CircularButtonState extends State<CircularButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _handlePress,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: widget.buttonColor,
          border: Border.all(color: widget.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              )
            else if (widget.imagePath!=null)
              switch (widget.imageType) {
                ImageType.image => Image.asset(widget.imagePath!, width: 24),
                ImageType.svg => SvgPicture.asset(widget.imagePath!, width: 24),
              },
            const SizedBox(width: 12),
            Text(
              _isLoading ? 'Please wait...' : widget.buttonText,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } catch (e) {
      print('Button press error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

enum ImageType { image, svg }
