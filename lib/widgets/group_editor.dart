import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum GroupEditorMode {
  create,
  edit,
}

class GroupEditor extends StatefulWidget {
  final GroupEditorMode mode;
  final String initialTitle;
  final List<String> forbiddenNames;

  GroupEditor(
    this.mode, {
    super.key,
    this.initialTitle = '',
    this.forbiddenNames = const [],
  });

  @override
  State<GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<GroupEditor> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleEditingController = TextEditingController();

  String? _validateTitle(String? title) {
    if (title == null || title.isEmpty) {
      return tr('group_title_empty_hint');
    }
    if (widget.forbiddenNames
        .any((f) => f.toLowerCase() == title.toLowerCase())) {
      return tr('group_title_already_used_hint');
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _titleEditingController.text);
    }
  }

  @override
  void initState() {
    _titleEditingController.text = widget.initialTitle;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            autofocus: true,
            controller: _titleEditingController,
            decoration: InputDecoration(
              labelText: tr('group_title_label'),
            ),
            validator: (value) => _validateTitle(value),
            onFieldSubmitted: (value) => _submit(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () => _submit(),
                  child: Text(
                    widget.mode == GroupEditorMode.create
                        ? tr('create')
                        : tr('apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleEditingController.dispose();
    super.dispose();
  }
}
