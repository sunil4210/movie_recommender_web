import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFormField extends FormField<String> {
  AppFormField({
    super.key,
    this.controller,
    String? initialValue,
    String? labelText,
    String? hintText,
    this.focusNode,
    InputDecoration decoration = const InputDecoration(),
    EdgeInsets? padding,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    bool autofocus = false,
    bool readOnly = false,
    bool obscureText = false,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    GestureTapCallback? onTap,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
    super.onSaved,
    super.validator,
    List<TextInputFormatter>? inputFormatters,
    bool? enabled,
    Widget? suffixIcon,
    Widget? prefixIcon,
    AutovalidateMode? autovalidateMode,
  }) : super(
         initialValue: controller != null ? controller.text : (initialValue ?? ''),
         enabled: enabled ?? decoration.enabled,
         autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
         builder: (FormFieldState<String> field) {
           final _AppFormFieldState state = field as _AppFormFieldState;

           void onChangedHandler(String value) {
             onChanged?.call(value);
             field.didChange(value);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (labelText != null) ...[
                 Text(
                   labelText,
                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                 ),
                 const SizedBox(height: 8),
               ],
               TextField(
                 controller: state._effectiveController,
                 focusNode: state._focusNode,
                 decoration: InputDecoration(
                   filled: true,
                   fillColor: AppColors.backgroundCard,
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppColors.grey300),
                   ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppColors.grey300),
                   ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                   ),
                   errorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppColors.error),
                   ),
                   focusedErrorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: AppColors.error, width: 1.5),
                   ),
                   hintText: hintText,
                   hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
                   suffixIcon: suffixIcon,
                   prefixIcon: prefixIcon,
                   contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                 ),
                 keyboardType: keyboardType,
                 textInputAction: textInputAction,
                 style: style ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                 textAlign: textAlign,
                 obscureText: obscureText,
                 textCapitalization: textCapitalization,
                 autofocus: autofocus,
                 readOnly: readOnly,
                 maxLines: maxLines,
                 minLines: minLines,
                 maxLength: maxLength,
                 onChanged: onChangedHandler,
                 onTap: onTap,
                 onEditingComplete: onEditingComplete,
                 onSubmitted: onFieldSubmitted,
                 inputFormatters: inputFormatters,
                 enabled: enabled ?? decoration.enabled,
               ),
               if (field.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 4, left: 4),
                   child: Text(field.errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                 ),
             ],
           );
         },
       );

  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  FormFieldState<String> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;
  late FocusNode _focusNode;

  TextEditingController? get _effectiveController => widget.controller ?? _controller;

  @override
  AppFormField get widget => super.widget as AppFormField;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(AppFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null) {
        _controller = TextEditingController.fromValue(oldWidget.controller!.value);
      }
      if (widget.controller != null) {
        setValue(widget.controller!.text);
        if (oldWidget.controller == null) _controller = null;
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    if (_effectiveController != null && value != null) {
      if (_effectiveController!.text != value) _effectiveController!.text = value;
    }
    super.didChange(value);
  }

  @override
  void reset() {
    super.reset();
    setState(() {
      _effectiveController?.text = widget.initialValue ?? "";
    });
  }

  void _handleControllerChanged() {
    if (_effectiveController?.text != value) didChange(_effectiveController?.text);
  }
}
