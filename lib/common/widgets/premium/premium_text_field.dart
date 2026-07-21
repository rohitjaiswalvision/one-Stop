import 'package:flutter/material.dart';
import 'package:sixam_mart/theme/premium_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Filled, borderless-until-focused text field used on auth screens (sign in,
/// OTP, sign up) — label sits above the field, focus ring is the brand color.
class PremiumTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool obscureText;
  final TextInputType inputType;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PremiumTextField({
    super.key, required this.label, this.hint, this.controller, this.focusNode,
    this.nextFocusNode, this.obscureText = false, this.inputType = TextInputType.text,
    this.prefix, this.suffix, this.errorText, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: Dimensions.paddingSizeExtraSmall),
        child: Text(label, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ),
      TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: inputType,
        onChanged: onChanged,
        onSubmitted: (_) => nextFocusNode != null ? FocusScope.of(context).requestFocus(nextFocusNode) : null,
        textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeDefault),
          errorText: errorText,
          filled: true,
          fillColor: PremiumTokens.tint(context, opacity: 0.05),
          prefixIcon: prefix,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.2),
          ),
        ),
      ),
    ]);
  }
}

/// Single-digit OTP box — used in a Row of 4-6 for the verification screen.
class OtpDigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final ValueChanged<String>? onChanged;
  const OtpDigitField({
    super.key, required this.controller, required this.focusNode, this.nextFocusNode, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = controller.text.isNotEmpty;
    return SizedBox(
      width: 52, height: 60,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
        onChanged: (value) {
          onChanged?.call(value);
          if (value.isNotEmpty && nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: PremiumTokens.tint(context, opacity: filled ? 0.10 : 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(color: filled ? Theme.of(context).primaryColor.withValues(alpha: 0.4) : Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.8),
          ),
        ),
      ),
    );
  }
}
