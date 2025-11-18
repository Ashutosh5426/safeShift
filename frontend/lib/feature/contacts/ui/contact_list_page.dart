import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/app/di/injections.dart';
import 'package:frontend/core/app/state/app_state.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/feature/common/common_network_image.dart';
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
    final appState = getIt<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
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
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: CommonNetworkWidget(
                          imageUrl: appState.profileImage,
                          width: 60,     // match diameter
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      appState.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stay Safe, Stay Connected',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.contacts_outlined),
                title: const Text('Contacts'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Spacer(),

              const Divider(thickness: 1),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  getIt<AppState>().logOut();
                },
              ),
            ],
          ),
        ),
      ),
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

// import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:frontend/core/app/state/app_state.dart';
// import 'package:frontend/core/app/di/injections.dart';
// import 'package:frontend/feature/contacts/ui/add_contacts_page.dart';
//
// class ContactListPage extends StatelessWidget {
//   final contacts = [
//     {
//       'name': 'Aarav Sharma',
//       'phone': '+91 9876543210',
//       'relationship': 'Brother',
//       'isPrimary': true,
//     },
//     {
//       'name': 'Priya Singh',
//       'phone': '+91 9123456789',
//       'relationship': 'Friend',
//       'isPrimary': false,
//     },
//   ];
//
//   ContactListPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FBFC),
//       appBar: AppBar(
//         title: const Text(
//           'Emergency Contacts',
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: const Color(0xFF028090),
//         centerTitle: true,
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(Icons.menu_rounded, color: Colors.white,),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//             );
//           }
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFFFBB13C),
//         child: const Icon(Icons.add, color: Colors.white),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => AddContactsPage()),
//           );
//         },
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: contacts.length,
//               itemBuilder: (context, index) {
//                 final c = contacts[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6.0),
//                   child: Slidable(
//                     key: ValueKey(c['phone']),
//                     startActionPane: ActionPane(
//                       motion: const StretchMotion(),
//                       children: [
//                         SlidableAction(
//                           onPressed: (_) {},
//                           backgroundColor: Colors.blue.shade400,
//                           icon: Icons.edit,
//                           label: 'Edit',
//                         ),
//                       ],
//                     ),
//                     endActionPane: ActionPane(
//                       motion: const StretchMotion(),
//                       children: [
//                         SlidableAction(
//                           onPressed: (_) {},
//                           backgroundColor: Colors.red.shade400,
//                           icon: Icons.delete,
//                           label: 'Delete',
//                         ),
//                       ],
//                     ),
//                     child: Card(
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 3,
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: const Color(0xFF028090),
//                           child: Text(
//                             "c['name']![0]",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         title: Text(
//                           "c['name']!",
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text('${c['phone']!}\n${c['relationship']}'),
//                         isThreeLine: true,
//                         // trailing: c['isPrimary']
//                         trailing: true
//                             ? Chip(
//                                 label: const Text(
//                                   'Primary',
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                                 backgroundColor: const Color(0xFFFBB13C),
//                               )
//                             : null,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topRight: Radius.circular(24),
//             bottomRight: Radius.circular(24),
//           ),
//         ),
//         child: Container(
//           color: Theme.of(context).colorScheme.surface,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               DrawerHeader(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor,
//                   borderRadius: const BorderRadius.only(
//                     topRight: Radius.circular(24),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     const CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white,
//                       child: Icon(Icons.person, size: 36, color: Colors.black87),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'SafeShift User',
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       'Stay Safe, Stay Connected',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Drawer items
//               ListTile(
//                 leading: const Icon(Icons.contacts_outlined),
//                 title: const Text('Contacts'),
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//               ),
//
//               const Spacer(),
//
//               const Divider(thickness: 1),
//
//               ListTile(
//                 leading: const Icon(Icons.logout, color: Colors.redAccent),
//                 title: const Text(
//                   'Logout',
//                   style: TextStyle(color: Colors.redAccent),
//                 ),
//                 onTap: () {
//                   getIt<AppState>().logOut();
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
