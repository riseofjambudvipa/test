import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/core/video/background_music_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/export_panel/audio_enhancement_card.dart';

void main() {
  testWidgets('AudioEnhancementCard renders switches and triggers callbacks',
      (tester) async {
    bool studioSound = false;
    bool audioCrossfade = true;
    BackgroundMusicConfig bgm = const BackgroundMusicConfig();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AudioEnhancementCard(
                  enableStudioSound: studioSound,
                  onStudioSoundChanged: (val) {
                    setState(() {
                      studioSound = val;
                    });
                  },
                  enableAudioCrossfade: audioCrossfade,
                  onAudioCrossfadeChanged: (val) {
                    setState(() {
                      audioCrossfade = val;
                    });
                  },
                  backgroundMusic: bgm,
                  onBackgroundMusicChanged: (val) {
                    setState(() {
                      bgm = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // Verify elements are present
    expect(find.text('AI Studio Sound'), findsOneWidget);
    expect(find.text('PRO AUDIO'), findsOneWidget);
    expect(find.text('Smooth Cut Transitions'), findsOneWidget);
    expect(find.text('ANTI-CLICK'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('BGM DUCKING'), findsOneWidget);
    expect(find.text('ADD BACKGROUND MUSIC TRACK'), findsOneWidget);

    // 2 switches are rendered when no music is selected and studio sound is off
    expect(find.byType(Switch), findsNWidgets(2));

    // Toggle Smooth Cut Transitions
    final crossfadeSwitch = find.byType(Switch).at(1);
    await tester.tap(crossfadeSwitch);
    await tester.pumpAndSettle();

    expect(audioCrossfade, isFalse);

    // Toggle AI Studio Sound
    final studioSoundSwitch = find.byType(Switch).first;
    await tester.tap(studioSoundSwitch);
    await tester.pumpAndSettle();

    expect(studioSound, isTrue);
  });

  testWidgets('AudioEnhancementCard renders platform loudness chips and de-esser controls when studio sound is enabled',
      (tester) async {
    bool studioSound = true;
    AudioMasteringConfig mastering = const AudioMasteringConfig(
      enableStudioSound: true,
      platform: AudioMasteringPlatform.socialShorts,
      enableDeEsser: true,
      deEsserIntensity: 0.40,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AudioEnhancementCard(
                  enableStudioSound: studioSound,
                  onStudioSoundChanged: (val) {
                    setState(() {
                      studioSound = val;
                    });
                  },
                  audioMastering: mastering,
                  onAudioMasteringChanged: (val) {
                    setState(() {
                      mastering = val;
                    });
                  },
                  enableAudioCrossfade: true,
                  onAudioCrossfadeChanged: (_) {},
                );
              },
            ),
          ),
        ),
      ),
    );

    // Platform Loudness section
    expect(find.text('Loudness Standard'), findsOneWidget);
    expect(find.text('-14 LUFS'), findsOneWidget);
    expect(find.text('Shorts / TikTok (-14 LUFS)'), findsOneWidget);
    expect(find.text('Broadcast (-16 LUFS)'), findsOneWidget);
    expect(find.text('Cinema (-23 LUFS)'), findsOneWidget);

    // Tap Broadcast (-16 LUFS)
    await tester.tap(find.text('Broadcast (-16 LUFS)'));
    await tester.pumpAndSettle();

    expect(mastering.platform, AudioMasteringPlatform.broadcastPodcast);
    expect(find.text('-16 LUFS'), findsOneWidget);

    // Vocal De-Esser
    expect(find.text('Vocal De-Esser'), findsOneWidget);
    expect(find.text('SIBILANCE'), findsOneWidget);
    expect(find.text('De-Esser Intensity'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);

    // Adjust De-Esser intensity
    final deEsserSlider = find.byType(Slider).first;
    await tester.drag(deEsserSlider, const Offset(50, 0));
    await tester.pumpAndSettle();

    expect(mastering.deEsserIntensity, greaterThan(0.40));
  });

  testWidgets('AudioEnhancementCard renders music track controls when track is configured',
      (tester) async {
    BackgroundMusicConfig bgm = const BackgroundMusicConfig(
      musicPath: '/music/upbeat_lofi_vibes.mp3',
      volume: 0.25,
      enableDucking: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AudioEnhancementCard(
                  enableStudioSound: false,
                  onStudioSoundChanged: (_) {},
                  enableAudioCrossfade: true,
                  onAudioCrossfadeChanged: (_) {},
                  backgroundMusic: bgm,
                  onBackgroundMusicChanged: (val) {
                    setState(() {
                      bgm = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // Verify music file name is shown
    expect(find.text('upbeat_lofi_vibes.mp3'), findsOneWidget);
    expect(find.text('Music Volume'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Smart Voice Ducking'), findsOneWidget);
    expect(find.text('-12 dB'), findsOneWidget);

    // 3 switches now rendered (Studio sound, crossfade, ducking)
    expect(find.byType(Switch), findsNWidgets(3));

    // Toggle ducking switch
    final duckingSwitch = find.byType(Switch).last;
    await tester.tap(duckingSwitch);
    await tester.pumpAndSettle();

    expect(bgm.enableDucking, isFalse);

    // Tap remove track button
    final removeBtn = find.byIcon(Icons.close_rounded);
    expect(removeBtn, findsOneWidget);
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(bgm.hasMusic, isFalse);
    expect(find.text('ADD BACKGROUND MUSIC TRACK'), findsOneWidget);
  });
}
