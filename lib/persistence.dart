import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

import 'package:collection/collection.dart';

class PersistentList<T> extends DelegatingList<T> {
  final Storage _storage;

  PersistentList(String fileName)
      : _storage = new Storage(fileName),
        super([]) {
    super.addAll(_storage.load() ?? []);
  }

  add(Object object) => withPersistence(super.add, object);

  addAll(Iterable<T> elements) => withPersistence(super.addAll, elements);

  insert(int index, T element) => withPersistence(super.insert, index, element);

  insertAll(int index, Iterable<T> iterable) => withPersistence(super.insertAll, index, iterable);

  remove(Object object) => withPersistence(super.remove, object);

  removeLast() => withPersistence(super.removeLast);

  removeAt(int index) => withPersistence(super.removeAt, index);

  removeRange(int start, int end) => withPersistence(super.removeRange, start, end);

  removeWhere(bool test(T element)) => withPersistence(super.removeWhere, test);

  withPersistence(Function function, [dynamic param1, dynamic param2]) {
    if (param1 == null)
      function();
    else
      function(param1);
    _storage.save(this);
  }

  save() {
    _storage.save(this);
  }
}

class PersistentSet<T> extends DelegatingSet<T> {
  final Storage storage;

  PersistentSet(String fileName)
      : storage = new Storage(fileName),
        super(new Set()) {
    super.addAll(storage.load() ?? []);
  }

  add(Object object) => withStorage(super.add, object);

  addAll(Iterable<T> elements) => withStorage(super.addAll, elements);

  remove(Object object) => withStorage(super.remove, object);

  removeAll(Iterable<Object> elements) => withStorage(super.removeAll, elements);

  removeWhere(bool test(T element)) => withStorage(super.removeWhere, test);
  clear() => withStorage(super.clear);


  withStorage(Function function, [dynamic param]) {
    function(param);
    storage.save(this.toList());
  }
}

class PersistentMap<T> extends DelegatingMap<String, T> {
  final Storage storage;

  PersistentMap(String fileName)
      : storage = new Storage(fileName),
        super({}) {
    super.addAll(storage.load() ?? {});
  }

  operator []=(String key, T value) => withPersistence((k, v) => super[key] = value, key, value);

  addAll(Map<String, T> elements) => withPersistence(super.addAll, elements);

  remove(Object object) => withPersistence(super.remove, object);

  withPersistence(Function function, [dynamic param1, dynamic param2]) {
    if(param1 == null)
      function();
    else if(param2 == null)
      function(param1);
    else
      function(param1, param2);
    storage.save(this);
  }
}

class Storage {
  static const encoder = const JsonEncoder.withIndent('  ');
  final File file;

  static String fromProjectDirAsDefault(String fileName) {
    if(isAbsolute(fileName))
      return fileName;
    return dirname(dirname(Platform.script.toFilePath())) + '/' + fileName;
  }

  Storage(String fileName) : file = new File(fromProjectDirAsDefault(fileName)) {
    if(!file.existsSync()) {
      file.createSync(recursive: true);
    }
  }

  Object load() {
    try {
      return JSON.decode(file.readAsStringSync());
    } catch(e) {
      return null;
    }
  }

  void save(Object object) {
    file.writeAsStringSync(encoder.convert(object));
  }
}

class PersistentEntityCollection<E extends Entity> extends DelegatingSet<E> {
  final Storage storage;
  final Map<String, E> _data = {};

  PersistentEntityCollection(String fileName, Serializer<E> serializer)
      : storage = new Storage(fileName), super(new Set<E>()) {
    var rawItems = storage.load() as List<Map>;
    var serialized = rawItems.map(serializer.fromJson).toSet();
    var map = new Map.fromIterable(serialized, key: (E e) => e.id);
    _data.addAll(map);
    super.addAll(serialized);
  }

  withStorage(Function function, [dynamic param]) {
    function(param);
    storage.save(this.toList());
  }

  E operator [](String id) => _data.containsKey(id) ? _data[id] : null;


  add(E object) {
    _data[object.id] = object;
    withStorage(super.add, object);
  }

  addAll(Iterable<E> elements) {
    _data.addAll(new Map.fromIterable(elements, key: (E e) => e.id));
    withStorage(super.addAll, elements);
  }

  remove(Object object) {
    _data.remove((object as E).id);
    withStorage(super.remove, object);
  }

  removeAll(Iterable<Object> elements) {
    elements.forEach((o) => _data.remove((o as E).id));
    withStorage(super.removeAll, elements);
  }

  removeWhere(bool test(E element)) {
    _data.values.where(test).forEach((o) => _data.remove(o.id));
    withStorage(super.removeWhere, test);
  }

  clear() {
    _data.clear();
    withStorage(super.clear);
  }
}

class PersistentObject<E> {
  final Storage _storage;
  E _entity;
  E get entity => _entity;

  PersistentObject(String fileName, Serializer<E> serializer)
      : _storage = new Storage(fileName) {
    var rawItem = _storage.load()  as Map;
    _entity = serializer.fromJson(rawItem);
  }
  save() {
    _storage.save(this);
  }
}

abstract class Entity {
  String get id;

  bool operator ==(Object other) => other is Entity && id == other.id;

  int get hashCode => id.hashCode;
}

abstract class Serializer<T>{
  const Serializer();
  T fromJson(Map input);
  Map toJson(T input);
}