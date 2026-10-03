import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  // Ajouter une note
  void ajouterNote(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter une note'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                ),
                maxLines: 4,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuler'),
            ),

            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  return;
                }

                await FirebaseFirestore.instance.collection('notes').add({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'userId': user.uid,
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  // Modifier une note
  void modifierNote(
    BuildContext context,
    String id,
    String title,
    String content,
  ) {
    final titleController = TextEditingController(text: title);
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier la note'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                ),
                maxLines: 4,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuler'),
            ),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('notes')
                    .doc(id)
                    .update({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  // Supprimer une note
  Future<void> supprimerNote(String id) async {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(id)
        .delete();
  }

  // Déconnexion
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes notes'),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where(
              'userId',
              isEqualTo: user?.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Une erreur est survenue'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notes = snapshot.data!.docs;

          if (notes.isEmpty) {
            return const Center(
              child: Text('Aucune note pour le moment'),
            );
          }

          return ListView.builder(
            itemCount: notes.length,

            itemBuilder: (context, index) {
              final note = notes[index];

              final title = note['title'];
              final content = note['content'];

              return ListTile(
                leading: const Icon(Icons.note),

                title: Text(title),

                subtitle: Text(content),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modifier
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        modifierNote(
                          context,
                          note.id,
                          title,
                          content,
                        );
                      },
                    ),

                    // Supprimer
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        supprimerNote(note.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ajouterNote(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}