import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'AboutApp', 'Failed to load app version: $e');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'AboutApp', 'Failed to open URL $urlString: $e');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryText,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCreditCard({
    required String title,
    required String subtitle,
    required String description,
    required String license,
    required String url,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg,
        borderRadius: 10,
        borderOpacity: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  license,
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _launchUrl(url),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: AppTheme.accentCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)?.visitWebsite ?? 'Visit Website',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          (l10n?.aboutApp ?? 'About CapStudio').toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Glowing Ambient background gradients
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlowingBackgroundPainter(
                  primaryGlow: AppTheme.accentOrange,
                  secondaryGlow: AppTheme.accentCyan,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(isCompactWidth ? 12.0 : 24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: EdgeInsets.all(isCompactWidth ? 16.0 : 28.0),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: 12,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Brand Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.accentOrange.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: AppTheme.cardBg,
                                  child: Icon(Icons.movie_creation_outlined,
                                      color: AppTheme.mutedText, size: 40),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'CapStudio',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n?.systemVersion ?? 'Version'} $_appVersion',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.aboutAppSubtitle ??
                                '100% Offline, Privacy-First AI Captioning & Subtitle Studio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppTheme.borderGlass, height: 40),

                    // Section 2: Core Technologies & Credits
                    _buildSectionHeader(l10n?.aboutAppThanks ??
                        'Open-Source Foundations & Core Technologies'),
                    const SizedBox(height: 16),

                    _buildCreditCard(
                      title: 'whisper.cpp & OpenAI Whisper',
                      subtitle: 'Georgi Gerganov & OpenAI Contributors',
                      license: 'MIT License',
                      description: 'Provides the high-performance offline C++ speech inference engine and neural model weights powering CapStudio\'s automatic subtitle generation.',
                      url: 'https://github.com/ggerganov/whisper.cpp',
                    ),

                    _buildCreditCard(
                      title: 'FFmpeg Multimedia Framework',
                      subtitle: 'The FFmpeg Project & Community',
                      license: 'LGPL v2.1+ / GPL v3.0',
                      description: 'Industry-standard cross-platform media engine used for local audio extraction, video transcoding, filtergraph mixing, and burn-in subtitle rendering.',
                      url: 'https://ffmpeg.org',
                    ),

                    _buildCreditCard(
                      title: 'Flutter & Dart SDK',
                      subtitle: 'Google LLC & Open Source Contributors',
                      license: 'BSD 3-Clause',
                      description: 'Cross-platform native framework enabling 60fps hardware-accelerated user interfaces, animations, and cross-platform desktop & mobile execution.',
                      url: 'https://flutter.dev',
                    ),

                    _buildCreditCard(
                      title: 'Google Fonts (Outfit, Montserrat, Poppins & Studio Typefaces)',
                      subtitle: 'Google LLC & Independent Type Designers',
                      license: 'SIL OFL 1.1',
                      description: 'Expressive typography for application interfaces and customizable viral caption styles, including Outfit, Montserrat, Anton, Bebas Neue, and Poppins.',
                      url: 'https://fonts.google.com',
                    ),

                    _buildCreditCard(
                      title: 'OpenMoji Vector Emojis',
                      subtitle: 'OpenMoji Project & HfG Schwäbisch Gmünd',
                      license: 'CC BY-SA 4.0',
                      description: 'Comprehensive open-source emoji vector artwork integrated into CapStudio\'s animated caption overlays and keyword visualizers.',
                      url: 'https://openmoji.org',
                    ),

                    _buildCreditCard(
                      title: 'Google Noto Color & Animated Emoji',
                      subtitle: 'Google LLC',
                      license: 'SIL OFL 1.1 / Apache 2.0',
                      description: 'High-definition static color and animated vector emoji packs designed by Google, providing expressive visual sticker overlays for video captions.',
                      url: 'https://github.com/googlefonts/noto-emoji',
                    ),

                    _buildCreditCard(
                      title: 'Microsoft Fluent UI Emoji (3D & Flat)',
                      subtitle: 'Microsoft Corporation',
                      license: 'MIT License',
                      description: 'Modern, beautifully styled 3D and flat emoji sets by Microsoft, utilized in CapStudio keyword visualizers and animated sticker layers.',
                      url: 'https://github.com/microsoft/fluentui-emoji',
                    ),

                    _buildCreditCard(
                      title: 'Unicode CLDR & Emoji Annotations',
                      subtitle: 'Unicode Consortium',
                      license: 'Unicode License v3.0',
                      description: 'Common Locale Data Repository providing multilingual emoji metadata, localized keywords, and speech-to-emoji semantic mapping across 90+ languages.',
                      url: 'https://cldr.unicode.org',
                    ),

                    _buildCreditCard(
                      title: 'Isar Embedded Database',
                      subtitle: 'Simon Leier & Isar Community Contributors',
                      license: 'Apache 2.0',
                      description: 'Blazing fast, cross-platform embedded NoSQL database engine powering local project storage, subtitle schema persistence, and audio waveform caching.',
                      url: 'https://isar.dev',
                    ),

                    Divider(color: AppTheme.borderGlass, height: 40),

                    // Section 3: Legal & Store Compliance
                    _buildSectionHeader(l10n?.openSourceLicenses ?? 'Open Source Licenses'),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.openSourceComplianceDesc ??
                          'CapStudio incorporates open-source packages and dependencies. Full license texts, copyright notices, and software components are compiled in compliance with open-source licenses.',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: Text(
                          l10n?.btnViewAllLicenses ?? 'VIEW ALL PACKAGE LICENSES',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.12),
                          foregroundColor: AppTheme.accentOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.25)),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'CapStudio',
                            applicationVersion: _appVersion,
                            applicationLegalese: '© 2026 CapStudio. Licensed under GPL-3.0.',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
