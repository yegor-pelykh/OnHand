import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:on_hand/data/group.dart';

const keyGroups = 'g';

class GroupStorage extends ChangeNotifier {
  List<Group> _groups;

  int get groupsLength => _groups.length;

  bool get isEmpty => groupsLength == 0;

  bool get isNotEmpty => groupsLength > 0;

  String get json {
    final json = {
      keyGroups: _groups.map((b) => b.json).toList(),
    };
    return jsonEncode(json);
  }

  List<String> get titles {
    return _groups.map((g) => g.title).toList();
  }

  GroupStorage() : _groups = [];

  void _handleGroupChange() {
    notifyListeners();
  }

  Group? groupAt(int index) {
    return 0 <= index && index < _groups.length ? _groups[index] : null;
  }

  Group? groupFirstWhere(bool Function(Group) test) {
    final index = groupIndexWhere(test);
    if (index >= 0) {
      return _groups[index];
    }
    return null;
  }

  int groupIndexWhere(bool Function(Group) test) {
    return _groups.indexWhere(test);
  }

  Iterable<T> groupsMap<T>(T Function(Group) toElement) {
    return _groups.map(toElement);
  }

  Group addGroup(Group group) {
    _groups.add(group);
    group.addListener(_handleGroupChange);
    notifyListeners();
    return group;
  }

  void moveGroup(int oldIndex, int newIndex) {
    final Group group = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, group);
    notifyListeners();
  }

  void removeGroup(Group group) {
    group.removeListener(_handleGroupChange);
    _groups.remove(group);
    notifyListeners();
  }

  void replaceAll(List<Group> groups) {
    if (!_groupsEqual(_groups, groups)) {
      for (var g in _groups) {
        g.removeListener(_handleGroupChange);
      }
      _groups = groups;
      for (var g in _groups) {
        g.addListener(_handleGroupChange);
      }
      notifyListeners();
    }
  }

  void replaceByDefault() {
    replaceAll([
      Group(this, tr('default_group_title')),
    ]);
  }

  void replaceFromJson(String? jsonString) {
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      replaceAll(List<dynamic>.from(json[keyGroups])
          .map((jg) => Group.fromJson(this, jg))
          .toList());
    } else {
      replaceAll([]);
    }
  }

  void replaceFrom(GroupStorage storage) {
    replaceAll(storage._groups);
  }

  int indexOf(Group group) {
    return _groups.indexOf(group);
  }

  GroupStorage clone() {
    final storage = GroupStorage();
    storage.replaceAll(_groups.map((g) => g.clone(storage)).toList());
    return storage;
  }

  static bool _groupsEqual(List<Group> l1, List<Group> l2) {
    if (l1.length != l2.length) {
      return false;
    }
    for (var i = 0; i < l1.length; i++) {
      if (!Group.equals(l1[i], l2[i])) {
        return false;
      }
    }
    return true;
  }
}
