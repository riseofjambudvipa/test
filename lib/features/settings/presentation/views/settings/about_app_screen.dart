import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/theme.dart';

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
    } catch (_) {}
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.white,
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
        color: AppTheme.cardBg.withValues(alpha: 0.8),
        borderRadius: 10,
        borderOpacity: 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
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
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
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
                    'Visit Website',
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg.withValues(alpha: 0.8),
        title: Text(
          l10n.aboutApp.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
                padding: EdgeInsets.all(isCompactWidth ? 12.0 : 24.0),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg.withValues(alpha: 0.5),
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CapStudio',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.systemVersion} $_appVersion',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '100% Offline, Privacy-First AI Captioning & Subtitle Studio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 40),

                    // Section 2: Credits & Thanks
                    _buildSectionHeader(l10n.aboutAppThanks),
                    const SizedBox(height: 16),

                    _buildCreditCard(
                      title: 'whisper.cpp & OpenAI Whisper',
                      subtitle: 'Georgi Gerganov & OpenAI',
                      license: 'MIT License',
                      description: 'Provides the high-performance offline C++ speech-to-text inference engine and state-of-the-art AI model weights powering CapStudio\'s automatic subtitle generation.',
                      url: 'https://github.com/ggerganov/whisper.cpp',
                    ),

                    _buildCreditCard(
                      title: 'FFmpeg & FFmpegKit',
                      subtitle: 'The FFmpeg Project & Contributors',
                      license: 'LGPLv2.1 License',
                      description: 'The industry-standard, cross-platform multimedia framework used for local audio extraction, video transcoding, and burn-in subtitle rendering.',
                      url: 'https://ffmpeg.org',
                    ),

                    _buildCreditCard(
                      title: 'Unicode CLDR-JSON',
                      subtitle: 'Unicode Consortium',
                      license: 'Unicode License',
                      description: 'Provides the multi-language Common Locale Data Repository JSON data used to power localized emoji search names, tags, and translation annotations.',
                      url: 'https://github.com/unicode-org/cldr-json',
                    ),

                    _buildCreditCard(
                      title: 'OpenMoji, Noto & Fluent Emojis',
                      subtitle: 'OpenMoji, Google & Microsoft',
                      license: 'CC BY-SA 4.0 / SIL OFL / MIT',
                      description: 'Creative design packs used to build custom caption assets, including flat vector representations and high-definition 3D graphics.',
                      url: 'https://openmoji.org',
                    ),

                    _buildCreditCard(
                      title: 'Noto Sans CJK & Noto Color Emoji',
                      subtitle: 'Google LLC & Adobe Inc.',
                      license: 'SIL OFL 1.1',
                      description: 'Provides preinstalled multi-language fonts for Chinese (SC/TC), Japanese, and Korean translation subtitles, as well as the NotoColorEmoji.ttf vector font for localized emoji rendering.',
                      url: 'https://github.com/googlefonts/noto-cjk',
                    ),

                    _buildCreditCard(
                      title: 'Google Fonts',
                      subtitle: 'Various Type Designers',
                      license: 'SIL Open Font License 1.1',
                      description: 'Bundles clean, modern typography (including Inter and Outfit) for the application UI and customizable caption styling.',
                      url: 'https://fonts.google.com',
                    ),

                    const Divider(color: Colors.white10, height: 40),

                    // Section 3: Legal & Store Compliance
                    _buildSectionHeader('Open Source Licenses'),
                    const SizedBox(height: 12),
                    const Text(
                      'CapStudio relies on many other open-source libraries. A complete registry of all Dart packages, transitive dependencies, and full license texts is compiled below for legal store compliance.',
                      style: TextStyle(
                        color: Colors.white54,
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
                          l10n.btnViewAllLicenses,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'CapStudio',
                            applicationVersion: _appVersion,
                            applicationLegalese: '© 2026 CapStudio. All rights reserved.',
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
