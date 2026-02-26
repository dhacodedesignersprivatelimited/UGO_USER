import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'language_model.dart';
export 'language_model.dart';

class LanguageWidget extends StatefulWidget {
  const LanguageWidget({super.key});

  static String routeName = 'Language';
  static String routePath = '/language';

  @override
  State<LanguageWidget> createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  late LanguageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LanguageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Helper to build a language row
  Widget _buildLanguageRow({
    required String label,
    required String localeKey,
    required String languageCode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () async {
        setAppLanguage(context, languageCode);
        safeSetState(() {}); // Refresh UI to show selection
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: double.infinity,
        height: 56.0,
        decoration: BoxDecoration(
          // Logic: selected row gets light gray, others transparent
          color: isSelected ? const Color(0xFFE9E9E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FFLocalizations.of(context).getText(localeKey),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  fontSize: 16.0,
                ),
              ),
              Theme(
                data: ThemeData(
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) async {
                    if (val == true) {
                      setAppLanguage(context, languageCode);
                      safeSetState(() {});
                    }
                  },
                  // Style per requirements
                  activeColor: const Color(0xFFFF7A00),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF9E9E9E),
                    width: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine current language to drive UI state
    final currentLanguage = FFLocalizations.of(context).languageCode;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7A00), // Solid Orange
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30.0),
            onPressed: () => context.pop(),
          ),
          title: Text(
            FFLocalizations.of(context).getText('fmwribbv' /* Languages */),
            style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLanguageRow(
                  label: 'English',
                  localeKey: 'bh670gmz',
                  languageCode: 'en',
                  isSelected: currentLanguage == 'en',
                ),
                _buildLanguageRow(
                  label: 'Telugu',
                  localeKey: 'iih23n2v',
                  languageCode: 'te',
                  isSelected: currentLanguage == 'te',
                ),
                _buildLanguageRow(
                  label: 'Hindi',
                  localeKey: '6craqhm0',
                  languageCode: 'hi',
                  isSelected: currentLanguage == 'hi',
                ),
              ].divide(const SizedBox(height: 12.0)),
            ),
          ),
        ),
      ),
    );
  }
}