import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/colors.dart';

class CommonTextFormField extends StatefulWidget {
  final String? hintText;
  final TextEditingController textFieldController;
  final List<TextInputFormatter>? formatter;
  final String? value;
  final Widget? rightIcon;
  final Widget? leftIcon;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final double? textFontSize;
  final double? hintFontSize;
  final bool isNumeric;
  final bool readOnly;
  final String? Function(String?)? validator;
  final Function(String?)? onChanged;

  const CommonTextFormField({
    super.key,
    this.hintText,
    required this.textFieldController,
    this.value,
    this.formatter,
    this.rightIcon,
    this.leftIcon,
    this.focusNode,
    this.textFontSize,
    this.hintFontSize,
    this.isNumeric = true,
    this.readOnly = false,
    this.keyboardType = TextInputType.phone,
    this.validator,
    this.onChanged,
  });

  @override
  State<CommonTextFormField> createState() => _CommonTextFormFieldState();
}

class _CommonTextFormFieldState extends State<CommonTextFormField> {
  @override
  Widget build(BuildContext context) {
    double inputFontSize = widget.textFontSize ?? 14;
    double hintFontSize = widget.hintFontSize ?? 14;

    return Container(
      height: 65,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Row(
        children: [
          widget.leftIcon ?? const SizedBox.shrink(),
          Expanded(
            child: Center(
              child: TextFormField(
                focusNode: widget.focusNode,
                controller: widget.textFieldController,
                readOnly: widget.readOnly,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.formatter ?? null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: widget.hintText ?? '',
                  hintStyle: TextStyle(
                    fontSize: hintFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: widget.validator,
                onChanged: widget.onChanged,
                style: TextStyle(
                  fontSize: inputFontSize,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          widget.rightIcon ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
