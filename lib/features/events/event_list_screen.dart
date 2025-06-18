import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/event_controller.dart';
import '../../../core/models/event_model.dart';
import 'event_detail_screen.dart';
import '../../core/models/user_model.dart';
import 'event_form_screen.dart';
import '../../../core/controllers/auth_controller.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'), 
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authController = Provider.of<AuthController>(context, listen: false);
              await authController.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: eventController.getEvents(),
        builder: (context, snapshot) {
          // State handling
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar eventos',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum evento encontrado',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Events list
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(event.location),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EventDetailScreen(
                              event: event,
                            ), // Removed const
                      ),
                    );
                  },
                  trailing:
                      user?.isOrganization == true
                          ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                () => _confirmDelete(
                                  context,
                                  eventController,
                                  event.id,
                                ),
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          user?.isOrganization == true
              ? FloatingActionButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const EventFormScreen(), // Can stay const if FormScreen allows
                      ),
                    ),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EventController controller,
    String eventId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Tem certeza que deseja excluir este evento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await controller.deleteEvent(eventId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso')),
      );
    }
  }
}
