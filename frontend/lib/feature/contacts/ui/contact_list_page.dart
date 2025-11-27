import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/feature/common/app_drawer.dart';
import 'package:frontend/feature/common/common_app_bar.dart';
import 'package:frontend/feature/contacts/bloc/contacts_bloc.dart';
import 'package:frontend/feature/contacts/bloc/contacts_event.dart';
import 'package:frontend/feature/contacts/bloc/contacts_state.dart';
import 'package:frontend/feature/contacts/data/models/contacts_model.dart';
import 'package:frontend/feature/contacts/data/repository/contacts_repository.dart';
import 'package:frontend/feature/contacts/ui/add_contacts_page.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  late final ContactsBloc _bloc;

  @override
  void initState() {
    _bloc = ContactsBloc(ContactsRepository());
    _bloc.add(GetContactsEvent());
    super.initState();
  }

  Future<void> _onDeleteTapped(BuildContext ctx, ContactModel contact) async {
    final shouldDelete = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Delete "${contact.name}" (${contact.phone})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _bloc.add(DeleteContactEvent(contact.id));
    } else {
      Slidable.of(ctx)?.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackgroundColor,
      appBar: CommonAppBar(
        title: 'Contacts',
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: BlocListener<ContactsBloc, ContactsState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is DeleteContactSuccess) {
            /// After successful delete, refetch contacts
            _bloc.add(GetContactsEvent());
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Contact deleted')));
          } else if (state is DeleteContactError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<ContactsBloc, ContactsState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state is GetContactsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GetContactsError) {
              return Center(child: Text(state.message));
            }
            if (state is GetContactsSuccess) {
              final contacts = state.contacts;
              return ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final contact = contacts[index];

                  return Slidable(
                    key: ValueKey(contact.id),

                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (ctx) {
                            _onDeleteTapped(ctx, contact);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),

                    child: ListTile(
                      leading: CircleAvatar(child: Text(contact.name[0])),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped ${contact.name}')),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
      drawer: AppDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddContactsPage()),
          );
          if (added == true) {
            _bloc.add(GetContactsEvent());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }
}