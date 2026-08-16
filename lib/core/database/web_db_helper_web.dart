// lib/core/database/web_db_helper_web.dart
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class WebDbHelper {
  static const String _dbName = 'capstudio_web_db';
  static const String _storeName = 'projects';
  static const int _version = 1;

  static Future<web.IDBDatabase> _openDb() {
    final completer = Completer<web.IDBDatabase>();
    
    // Fallback if indexedDB is null (e.g. some strict incognito modes)
    if (web.window.indexedDB.isUndefinedOrNull) {
      completer.completeError('IndexedDB is not supported or is blocked');
      return completer.future;
    }

    final request = web.window.indexedDB.open(_dbName, _version);

    request.onupgradeneeded = ((web.IDBVersionChangeEvent event) {
      final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }).toJS;

    request.onsuccess = ((web.Event event) {
      final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
      completer.complete(db);
    }).toJS;

    request.onerror = ((web.Event event) {
      completer.completeError('Failed to open IndexedDB');
    }).toJS;

    return completer.future;
  }

  static Future<void> saveProjectWeb(String projectId, String jsonStr) async {
    final db = await _openDb();
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);
    
    final request = store.put(jsonStr.toJS, projectId.toJS);
    final completer = Completer<void>();
    
    request.onsuccess = ((web.Event event) {
      completer.complete();
    }).toJS;
    
    request.onerror = ((web.Event event) {
      completer.completeError('Failed to save project');
    }).toJS;
    
    await completer.future;
    db.close();
  }

  static Future<String?> getProjectWeb(String projectId) async {
    final db = await _openDb();
    final txn = db.transaction(_storeName.toJS, 'readonly');
    final store = txn.objectStore(_storeName);
    
    final request = store.get(projectId.toJS);
    final completer = Completer<String?>();
    
    request.onsuccess = ((web.Event event) {
      final result = request.result;
      if (result.isUndefinedOrNull) {
        completer.complete(null);
      } else {
        completer.complete((result as JSString).toDart);
      }
    }).toJS;
    
    request.onerror = ((web.Event event) {
      completer.completeError('Failed to get project');
    }).toJS;
    
    final result = await completer.future;
    db.close();
    return result;
  }

  static Future<List<String>> getAllProjectsWeb() async {
    final db = await _openDb();
    final txn = db.transaction(_storeName.toJS, 'readonly');
    final store = txn.objectStore(_storeName);
    
    final request = store.openCursor();
    final completer = Completer<List<String>>();
    final list = <String>[];
    
    request.onsuccess = ((web.Event event) {
      final cursor = request.result as web.IDBCursorWithValue?;
      if (cursor == null || cursor.isUndefinedOrNull) {
        completer.complete(list);
      } else {
        final val = cursor.value as JSString;
        list.add(val.toDart);
        cursor.continue_();
      }
    }).toJS;
    
    request.onerror = ((web.Event event) {
      completer.completeError('Failed to cursor projects');
    }).toJS;
    
    final results = await completer.future;
    db.close();
    return results;
  }

  static Future<void> deleteProjectWeb(String projectId) async {
    final db = await _openDb();
    final txn = db.transaction(_storeName.toJS, 'readwrite');
    final store = txn.objectStore(_storeName);
    
    final request = store.delete(projectId.toJS);
    final completer = Completer<void>();
    
    request.onsuccess = ((web.Event event) {
      completer.complete();
    }).toJS;
    
    request.onerror = ((web.Event event) {
      completer.completeError('Failed to delete project');
    }).toJS;
    
    await completer.future;
    db.close();
  }
}
