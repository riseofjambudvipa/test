import 'dart:async';
import 'dart:io';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/audio/audio_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/downloader/binary_downloader_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/dashboard/presentation/controllers/dashboard_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mocks for AudioService
class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockAudioService extends Mock implements AudioService {}

// Mocks for Riverpod
class MockRef extends Mock implements Ref {}

// Mocks for EditorController
class MockEditorController extends Mock implements EditorController {}

// Mocks for DashboardController
class MockDashboardController extends Mock implements DashboardController {}

// Mocks for Services
class MockWhisperService extends Mock implements WhisperService {}
class MockSettingsService extends Mock implements SettingsService {}
class MockBinaryDownloaderService extends Mock implements BinaryDownloaderService {}

// Mocks for Process/IO
class MockProcess extends Mock implements Process {}

// Mocks for Database
class MockIsar extends Mock implements Isar {}
class MockIsarService extends Mock implements IsarService {}

// Mocks for Network
class MockHttpClient extends Mock implements http.Client {}
class MockHttpResponse extends Mock implements http.Response {}
class MockStreamedResponse extends Mock implements http.StreamedResponse {}

// Custom helper stream subscription mock if needed
class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}
