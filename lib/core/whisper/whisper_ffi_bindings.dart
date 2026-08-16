// ignore_for_file: camel_case_types, non_constant_identifier_names, camel_case_extensions
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Native struct representations matching whisper.h on 64-bit platforms

final class WhisperContext extends Opaque {}
final class WhisperState extends Opaque {}

final class WhisperContextParams extends Struct {
  @Bool()
  external bool use_gpu;
  @Bool()
  external bool flash_attn;
  @Int32()
  external int gpu_device;
  @Bool()
  external bool dtw_token_timestamps;
  @Int32()
  external int dtw_aheads_preset;
  @Int32()
  external int dtw_n_top;
  
  // struct whisper_aheads
  @Size()
  external int dtw_aheads_n_heads;
  external Pointer<Void> dtw_aheads_heads;

  @Size()
  external int dtw_mem_size;
}

final class WhisperVadParams extends Struct {
  @Float()
  external double threshold;
  @Int32()
  external int min_speech_duration_ms;
  @Int32()
  external int min_silence_duration_ms;
  @Float()
  external double max_speech_duration_s;
  @Int32()
  external int speech_pad_ms;
  @Float()
  external double samples_overlap;
}

// Minimal whisper_full_params structure targeting fields we need to customize.
// To avoid layout mismatch crashes, we populate this in C/C++ memory using
// whisper_full_default_params_by_ref and modify it by offset or field access.
final class WhisperFullParams extends Struct {
  @Int32()
  external int strategy;

  @Int32()
  external int n_threads;
  @Int32()
  external int n_max_text_ctx;
  @Int32()
  external int offset_ms;
  @Int32()
  external int duration_ms;

  @Bool()
  external bool translate;
  @Bool()
  external bool no_context;
  @Bool()
  external bool no_timestamps;
  @Bool()
  external bool single_segment;
  @Bool()
  external bool print_special;
  @Bool()
  external bool print_progress;
  @Bool()
  external bool print_realtime;
  @Bool()
  external bool print_timestamps;

  @Bool()
  external bool token_timestamps;
  @Float()
  external double thold_pt;
  @Float()
  external double thold_ptsum;
  @Int32()
  external int max_len;
  @Bool()
  external bool split_on_word;
  @Int32()
  external int max_tokens;

  @Bool()
  external bool debug_mode;
  @Int32()
  external int audio_ctx;
  @Bool()
  external bool tdrz_enable;

  external Pointer<Utf8> suppress_regex;
  external Pointer<Utf8> initial_prompt;
  @Bool()
  external bool carry_initial_prompt;
  external Pointer<Int32> prompt_tokens;
  @Int32()
  external int prompt_n_tokens;

  external Pointer<Utf8> language;
  @Bool()
  external bool detect_language;

  @Bool()
  external bool suppress_blank;
  @Bool()
  external bool suppress_nst;

  @Float()
  external double temperature;
  @Float()
  external double max_initial_ts;
  @Float()
  external double length_penalty;

  @Float()
  external double temperature_inc;
  @Float()
  external double entropy_thold;
  @Float()
  external double logprob_thold;
  @Float()
  external double no_speech_thold;

  // greedy
  @Int32()
  external int greedy_best_of;

  // beam_search
  @Int32()
  external int beam_search_beam_size;
  @Float()
  external double beam_search_patience;

  // callbacks (Pointers)
  external Pointer<Void> new_segment_callback;
  external Pointer<Void> new_segment_callback_user_data;

  external Pointer<Void> progress_callback;
  external Pointer<Void> progress_callback_user_data;

  external Pointer<Void> encoder_begin_callback;
  external Pointer<Void> encoder_begin_callback_user_data;

  external Pointer<Void> abort_callback;
  external Pointer<Void> abort_callback_user_data;

  external Pointer<Void> logits_filter_callback;
  external Pointer<Void> logits_filter_callback_user_data;

  external Pointer<Void> grammar_rules;
  @Size()
  external int n_grammar_rules;
  @Size()
  external int i_start_rule;
  @Float()
  external double grammar_penalty;

  @Bool()
  external bool vad;
  external Pointer<Utf8> vad_model_path;

  // Embedded struct
  external WhisperVadParams vad_params;
}

// C-API bindings declarations
typedef whisper_print_system_info_df = Pointer<Utf8> Function();
typedef whisper_print_system_info_df_dart = Pointer<Utf8> Function();

typedef whisper_init_from_file_with_params_df = Pointer<WhisperContext> Function(
  Pointer<Utf8> pathModel,
  WhisperContextParams params,
);
typedef whisper_init_from_file_with_params_df_dart = Pointer<WhisperContext> Function(
  Pointer<Utf8> pathModel,
  WhisperContextParams params,
);

typedef whisper_free_df = Void Function(Pointer<WhisperContext> ctx);
typedef whisper_free_df_dart = void Function(Pointer<WhisperContext> ctx);

typedef whisper_context_default_params_by_ref_df = Pointer<WhisperContextParams> Function();
typedef whisper_context_default_params_by_ref_df_dart = Pointer<WhisperContextParams> Function();

typedef whisper_full_default_params_by_ref_df = Pointer<WhisperFullParams> Function(Int32 strategy);
typedef whisper_full_default_params_by_ref_df_dart = Pointer<WhisperFullParams> Function(int strategy);

typedef whisper_full_df = Int32 Function(
  Pointer<WhisperContext> ctx,
  Pointer<WhisperFullParams> params,
  Pointer<Float> samples,
  Int32 nSamples,
);
typedef whisper_full_df_dart = int Function(
  Pointer<WhisperContext> ctx,
  Pointer<WhisperFullParams> params,
  Pointer<Float> samples,
  int nSamples,
);

typedef whisper_full_n_segments_df = Int32 Function(Pointer<WhisperContext> ctx);
typedef whisper_full_n_segments_df_dart = int Function(Pointer<WhisperContext> ctx);

typedef whisper_full_get_segment_text_df = Pointer<Utf8> Function(Pointer<WhisperContext> ctx, Int32 iSegment);
typedef whisper_full_get_segment_text_df_dart = Pointer<Utf8> Function(Pointer<WhisperContext> ctx, int iSegment);

typedef whisper_full_n_tokens_df = Int32 Function(Pointer<WhisperContext> ctx, Int32 iSegment);
typedef whisper_full_n_tokens_df_dart = int Function(Pointer<WhisperContext> ctx, int iSegment);

typedef whisper_full_get_token_text_df = Pointer<Utf8> Function(Pointer<WhisperContext> ctx, Int32 iSegment, Int32 iToken);
typedef whisper_full_get_token_text_df_dart = Pointer<Utf8> Function(Pointer<WhisperContext> ctx, int iSegment, int iToken);

// We need the token data structure fields (specifically t0, t1, and p)
// Rather than mapping the token struct directly across various compiler layouts, we define FFI signatures
// to query individual properties, or define a copy struct that matches standard x64 compilation.
final class WhisperTokenData extends Struct {
  @Int32()
  external int id;
  @Int32()
  external int tid;
  @Float()
  external double p;
  @Float()
  external double plog;
  @Float()
  external double pt;
  @Float()
  external double ptsum;
  
  @Int64()
  external int t0;
  @Int64()
  external int t1;
  @Int64()
  external int t_dtw;

  @Float()
  external double vlen;
}

typedef whisper_full_get_token_data_df = WhisperTokenData Function(Pointer<WhisperContext> ctx, Int32 iSegment, Int32 iToken);
typedef whisper_full_get_token_data_df_dart = WhisperTokenData Function(Pointer<WhisperContext> ctx, int iSegment, int iToken);

typedef whisper_token_eot_df = Int32 Function(Pointer<WhisperContext> ctx);
typedef whisper_token_eot_df_dart = int Function(Pointer<WhisperContext> ctx);

typedef whisper_full_lang_id_df = Int32 Function(Pointer<WhisperContext> ctx);
typedef whisper_full_lang_id_df_dart = int Function(Pointer<WhisperContext> ctx);

typedef whisper_lang_str_df = Pointer<Utf8> Function(Int32 langId);
typedef whisper_lang_str_df_dart = Pointer<Utf8> Function(int langId);
