import 'package:flutter/material.dart';

/// Design system compartilhado com o Passagem WEB (uti_passagem).
///
/// A identidade visual e a mesma do Passagem WEB: paleta (azul da logomarca
/// sobre cinzas neutros), formas, tipografia Montserrat e o estilo
/// corporativo dos campos de formulario. As telas consomem apenas
/// `Theme.of(context)` - cores estruturais nao devem ser hardcoded nos
/// widgets; verde/vermelho/laranja continuam permitidos pontualmente quando
/// tem significado clinico (temperatura, alertas, status).

/// Azul institucional extraido da logomarca do hospital.
const Color kBrandBlue = Color(0xFF3158A8);

/// Variante clara do azul da logo para o modo escuro - o tom original nao
/// tem contraste suficiente sobre cinza escuro para texto e icones.
const Color _brandBlueOnDark = Color(0xFF9DBCF2);

// -- Cinzas neutros do modo escuro (R=G=B, sem tom esverdeado/azulado) ------
const Color _darkScaffold = Color(0xFF161616);
const Color _darkSurface = Color(0xFF1C1C1C);
const Color _darkCard = Color(0xFF1E1E1E);
const Color _darkElevated = Color(0xFF242424); // dialogos, menus
const Color _darkField = Color(0xFF2A2A2A); // fundo de campos de formulario
const Color _darkHover = Color(0xFF303030);
const Color _darkBorder = Color(0xFF303030); // divisorias e bordas de card
const Color _darkFieldBorder = Color(0xFF424242);
const Color _darkOutline = Color(0xFF5C5C5C);
const Color _darkText = Color(0xFFE6E6E6);
const Color _darkTextMuted = Color(0xFFACACAC);

// -- Neutros do modo claro ---------------------------------------------------
const Color _lightScaffold = Color(0xFFF4F5F7);
const Color _lightCardBorder = Color(0xFFE2E4E9);
const Color _lightField = Color(0xFFF8F9FB);
const Color _lightFieldHover = Color(0xFFF0F2F5);
const Color _lightFieldBorder = Color(0xFFD4D8DF);
const Color _lightChipBg = Color(0xFFECEEF1);
const Color _lightText = Color(0xFF1B1D22);
const Color _lightTextMuted = Color(0xFF565B66);

/// Raio pequeno e tecnico usado em campos, botoes e chips - visual de
/// sistema corporativo, nao de app movel.
const double _controlRadius = 6;
const double _cardRadius = 8;
const double _dialogRadius = 12;

/// Cores funcionais dos estados clinicos, com variante propria por tema -
/// as cores cruas do Material (Colors.red etc.) estouram no modo escuro.
/// Regra de uso: vermelho so para alerta real (febre, erro, acao
/// destrutiva); laranja para atencao/pendencia; verde para normalidade/
/// estavel; azul para informacao. Widgets acessam via
/// `Theme.of(context).extension<ClinicalColors>()!` (atalho: `context.clinical`).
@immutable
class ClinicalColors extends ThemeExtension<ClinicalColors> {
  const ClinicalColors({
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
    required this.neutral,
  });

  final Color danger;
  final Color warning;
  final Color success;
  final Color info;
  final Color neutral;

  /// Fundo suave para tags/realces do estado - mesma cor com alfa baixo,
  /// funciona sobre card claro e escuro.
  Color tagBackground(Color state) => state.withValues(alpha: 0.12);

  /// Borda discreta para tags do estado.
  Color tagBorder(Color state) => state.withValues(alpha: 0.38);

  static const light = ClinicalColors(
    danger: Color(0xFFB3261E),
    warning: Color(0xFFA05A00),
    success: Color(0xFF256E3D),
    info: Color(0xFF2F5DA8),
    neutral: Color(0xFF5C6470),
  );

  static const dark = ClinicalColors(
    danger: Color(0xFFF2989A),
    warning: Color(0xFFF0B860),
    success: Color(0xFF8CD5A2),
    info: Color(0xFF9DBCF2),
    neutral: Color(0xFFA5ACB8),
  );

  @override
  ClinicalColors copyWith({
    Color? danger,
    Color? warning,
    Color? success,
    Color? info,
    Color? neutral,
  }) =>
      ClinicalColors(
        danger: danger ?? this.danger,
        warning: warning ?? this.warning,
        success: success ?? this.success,
        info: info ?? this.info,
        neutral: neutral ?? this.neutral,
      );

  @override
  ClinicalColors lerp(ClinicalColors? other, double t) {
    if (other == null) return this;
    return ClinicalColors(
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

/// Atalho para os tokens clinicos do tema ativo.
extension ClinicalColorsX on BuildContext {
  ClinicalColors get clinical => Theme.of(this).extension<ClinicalColors>()!;
}

/// API consumida pelo main.dart; delega para o design system compartilhado.
class PassagemUtiTheme {
  static ThemeData get light => buildAppTheme(Brightness.light);
  static ThemeData get dark => buildAppTheme(Brightness.dark);
}

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = _buildColorScheme(brightness);
  final fieldBorder = isDark ? _darkFieldBorder : _lightFieldBorder;

  OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_controlRadius),
        borderSide: BorderSide(color: color, width: width),
      );

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_controlRadius),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Montserrat',
  );

  // Toda a tipografia e local: nenhuma estacao hospitalar precisa consultar
  // um servidor de fontes externo durante o uso do app.
  TextStyle heading(TextStyle? style, {FontWeight weight = FontWeight.w700}) =>
      (style ?? const TextStyle()).copyWith(
        fontFamily: 'Montserrat',
        fontWeight: weight,
        color: scheme.onSurface,
      );

  final textTheme = base.textTheme.copyWith(
    headlineSmall: heading(base.textTheme.headlineSmall),
    titleLarge: heading(base.textTheme.titleLarge),
    titleMedium: heading(base.textTheme.titleMedium, weight: FontWeight.w600),
  );

  return base.copyWith(
    textTheme: textTheme,
    extensions: [isDark ? ClinicalColors.dark : ClinicalColors.light],
    scaffoldBackgroundColor: isDark ? _darkScaffold : _lightScaffold,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: isDark ? _darkScaffold : _lightScaffold,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      // Sombra bem discreta no claro (da leve profundidade sobre o fundo
      // cinza); no escuro a separacao vem so da borda + tom do card.
      elevation: isDark ? 0 : 1,
      shadowColor: isDark ? Colors.transparent : const Color(0x1F000000),
      color: isDark ? _darkCard : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: isDark ? _darkBorder : _lightCardBorder),
      ),
      // Sem isso, decoracoes internas com cantos retos (ex.: a barra lateral
      // de status nos cards de leito) vazam para fora dos cantos
      // arredondados do card.
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? _darkElevated : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogRadius),
      ),
      titleTextStyle: textTheme.titleLarge,
      // Rodape com respiro consistente em todos os AlertDialog simples.
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      textStyle: TextStyle(
        color: isDark ? _darkScaffold : Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: isDark ? _darkText : const Color(0xE6313540),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primary.withValues(alpha: 0.15),
      circularTrackColor: scheme.primary.withValues(alpha: 0.15),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: scheme.outline, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outline,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : (isDark ? _darkField : _lightChipBg),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? _darkElevated : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? _darkElevated : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: isDark ? _darkElevated : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return (isDark ? _darkField : _lightField).withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.hovered) &&
            !states.contains(WidgetState.focused)) {
          return isDark ? _darkHover : _lightFieldHover;
        }
        return isDark ? _darkField : _lightField;
      }),
      hoverColor: Colors.transparent, // o fillColor acima ja trata o hover
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: inputBorder(fieldBorder),
      enabledBorder: inputBorder(fieldBorder),
      focusedBorder: inputBorder(scheme.primary, width: 1.6),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, width: 1.6),
      disabledBorder: inputBorder(fieldBorder.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.error)) {
          return TextStyle(color: scheme.error, fontWeight: FontWeight.w600);
        }
        if (states.contains(WidgetState.focused)) {
          return TextStyle(color: scheme.primary, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: scheme.onSurfaceVariant);
      }),
      helperStyle: TextStyle(color: scheme.onSurfaceVariant),
      suffixIconColor: scheme.onSurfaceVariant,
      prefixIconColor: scheme.onSurfaceVariant,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: controlShape,
        minimumSize: const Size(64, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: controlShape,
        minimumSize: const Size(64, 40),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        minimumSize: const Size(64, 40),
        side: BorderSide(color: scheme.outline),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: isDark ? _darkFieldBorder : _lightFieldBorder),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: isDark ? 0.22 : 0.10);
          }
          return isDark ? _darkCard : Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_controlRadius),
      ),
      side: BorderSide(color: isDark ? _darkFieldBorder : _lightFieldBorder),
      backgroundColor: isDark ? _darkField : _lightField,
      labelStyle: base.textTheme.labelMedium?.copyWith(color: scheme.onSurface),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      extendedTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.circular(8),
      thickness: WidgetStatePropertyAll(8),
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
  );
}

ColorScheme _buildColorScheme(Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: kBrandBlue,
    brightness: brightness,
  );

  if (brightness == Brightness.light) {
    return seeded.copyWith(
      // Azul exato da marca (o tonal gerado pelo seed desvia um pouco).
      primary: kBrandBlue,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: _lightText,
      onSurfaceVariant: _lightTextMuted,
      surfaceContainerHighest: _lightChipBg,
      surfaceContainerHigh: _lightFieldHover,
      surfaceContainerLow: _lightField,
      outline: const Color(0xFFA9AEB8),
      outlineVariant: _lightCardBorder,
    );
  }

  return seeded.copyWith(
    primary: _brandBlueOnDark,
    onPrimary: const Color(0xFF10254D),
    surface: _darkSurface,
    onSurface: _darkText,
    onSurfaceVariant: _darkTextMuted,
    surfaceContainerHighest: _darkField,
    surfaceContainerHigh: _darkElevated,
    surfaceContainerLow: const Color(0xFF1A1A1A),
    outline: _darkOutline,
    outlineVariant: _darkBorder,
  );
}
