import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/feature/common/circular_button.dart';
import 'package:frontend/feature/contacts/bloc/contacts_bloc.dart';
import 'package:frontend/feature/contacts/bloc/contacts_event.dart';
import 'package:frontend/feature/contacts/bloc/contacts_state.dart';
import 'package:frontend/feature/contacts/data/repository/contacts_repository.dart';

class AddContactsPage extends StatefulWidget {
  const AddContactsPage({super.key});

  @override
  State<AddContactsPage> createState() => _AddContactsPageState();
}

class _AddContactsPageState extends State<AddContactsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPrimary = false;
  String? _relationship;
  late TextEditingController _fullName;
  late TextEditingController _phoneNumber;
  late final ContactsBloc _bloc;

  @override
  void initState() {
    _fullName = TextEditingController();
    _phoneNumber = TextEditingController();
    _bloc = ContactsBloc(ContactsRepository());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        leading: InkWell(
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Contact', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF028090),
      ),
      body: BlocListener<ContactsBloc, ContactsState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is AddContactSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact added successfully')),
            );
            Navigator.of(context).pop(true);
          } else if (state is AddContactError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField(
                  'Full Name',
                  Icons.person,
                  controller: _fullName,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  'Phone Number',
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  controller: _phoneNumber,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Relationship'),
                  items: ['Friend', 'Parent', 'Sibling', 'Colleague']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _relationship = v),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  activeColor: const Color(0xFFFBB13C),
                  title: const Text('Set as Primary Contact'),
                  value: _isPrimary,
                  onChanged: (v) => setState(() => _isPrimary = v),
                ),
                const SizedBox(height: 24),
                CircularButton(
                  buttonText: 'Save Contact',
                  buttonColor: const Color(0xFF028090),
                  textColor: Colors.white,
                  onPressed: () async {
                    if (_formKey.currentState!.validate() == false) {
                      return; // ❌ Form not valid
                    }
                    if (_relationship == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error: Relationship field can't be empty",
                          ),
                        ),
                      );
                      return;
                    }
                    _bloc.add(
                      AddContactEvent(
                        name: _fullName.text,
                        phone: _phoneNumber.text,
                        relationship: _relationship!,
                        isPrimary: _isPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    required TextEditingController controller,
  }) {
    return TextFormField(
      decoration: _inputDecoration(label, icon: icon),
      keyboardType: keyboardType,
      controller: controller,
      onChanged: (_) => _formKey.currentState!.validate(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label cannot be empty";
        }

        if (label == "Phone Number") {
          return _validatePhoneNumber(value);
        }

        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF028090))
          : null,
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  String? _validatePhoneNumber(String value) {
    final phone = value.trim();

    // Basic length check (India: 10 digits)
    if (phone.length != 10) {
      return "Phone number must be 10 digits";
    }

    // Must contain only numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return "Phone number must contain only digits";
    }

    // Optional: Avoid starting with 0
    if (phone.startsWith("0")) {
      return "Phone number cannot start with 0";
    }

    return null; // valid
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phoneNumber.dispose();
    _bloc.close();
    super.dispose();
  }
}
