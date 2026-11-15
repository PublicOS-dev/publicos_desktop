import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

class EditInboxIdLabelSheet extends StatefulWidget {
  final Uint8List inboxId;
  final String currentLabel;
  final Function(Uint8List inboxId, String newLabel) onSave;

  const EditInboxIdLabelSheet({
    super.key,
    required this.inboxId,
    required this.currentLabel,
    required this.onSave,
  });

  @override
  State<EditInboxIdLabelSheet> createState() => _EditInboxIdLabelSheetState();
}

class _EditInboxIdLabelSheetState extends State<EditInboxIdLabelSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.currentLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(widget.inboxId, _labelController.text);
      // Navigator.pop(context); // Pop is handled by the caller after successful save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16, left: 16, right: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.editInboxIdLabelSheetTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(context.l10n.editInboxIdLabelSheetIdLabel(bytes32ToString(widget.inboxId)), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(labelText: context.l10n.editInboxIdLabelSheetNewLabel, border: const OutlineInputBorder()),
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.editInboxIdLabelSheetLabelRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: _submit,
              child: Text(context.l10n.editInboxIdLabelSheetSave),
            ),
          ],
        ),
      ),
    );
  }
}
