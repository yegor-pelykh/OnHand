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

  @override
  void initState() {
    _titleEditingController.text = widget.initialTitle;
    super.initState();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _titleEditingController.text);
    }
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
            decoration: const InputDecoration(
              labelText: 'Title *',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a group title.';
              }
              if (widget.forbiddenNames.any((f) => f.toLowerCase() == value.toLowerCase())) {
                return 'This title is already used by another group.';
              }
              return null;
            },
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
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _submit(),
                  child: Text(widget.mode == GroupEditorMode.create ? 'Create' : 'Apply'),
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
