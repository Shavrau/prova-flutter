import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/controllers/event_controller.dart';
import '../../../core/models/event_model.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/user_model.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);
    final authController = Provider.of<AuthController>(context);
    final user = Provider.of<UserModel?>(context);
    final isOrganization = user?.isOrganization ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
        actions: [
          if (isOrganization)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Criar Evento',
              onPressed: () => _navigateToCreateEvent(context),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _buildEventList(context, eventController, authController, user),
      floatingActionButton: isOrganization
          ? FloatingActionButton(
              onPressed: () => _navigateToCreateEvent(context),
              child: const Icon(Icons.add),
              tooltip: 'Criar Novo Evento',
            )
          : null,
    );
  }

  Widget _buildEventList(
    BuildContext context,
    EventController eventController,
    AuthController authController,
    UserModel? user,
  ) {
    return StreamBuilder<List<EventModel>>(
      stream: eventController.getEventsByUser(user?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao carregar eventos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente novamente mais tarde',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Recarregar a tela
                    Navigator.pushReplacementNamed(context, '/eventlist');
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando eventos...'),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum evento encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seja o primeiro a criar um evento!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                if (user?.isOrganization == true)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateEvent(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeiro Evento'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event, eventController, authController, user);
          },
        );
      },
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventModel event,
    EventController eventController,
    AuthController authController,
    UserModel? user,
  ) {
    // Checagem defensiva para todos os campos
    final title = (event.title).isNotEmpty ? event.title : 'Evento sem título';
    final location = (event.location).isNotEmpty ? event.location : 'Local não informado';
    final dateTime = event.dateTime;
    final description = event.description ?? '';
    final participants = event.participants ?? <String>[];

    // Se algum campo essencial estiver faltando, mostre um card de aviso
    if (title.isEmpty || location.isEmpty || dateTime == null) {
      return Card(
        color: Colors.red[50],
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Evento com dados inválidos ou incompletos. Verifique no painel de administração.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final currentUserId = authController.currentUser?.uid;
    final isOrganizer = currentUserId != null && eventController.isUserOrganizer(event, currentUserId);
    final isParticipating = currentUserId != null && eventController.isUserParticipating(event, currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEventDetail(context, event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOrganizer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ORGANIZADOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateTime != null
                        ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
                          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                        : 'Data não informada',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${participants.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!user!.isOrganization && !isOrganizer)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleParticipation(
                          context,
                          eventController,
                          event,
                          currentUserId!,
                          isParticipating,
                        ),
                        icon: Icon(isParticipating ? Icons.exit_to_app : Icons.add),
                        label: Text(isParticipating ? 'Sair' : 'Participar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isParticipating ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (isOrganizer) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToEditEvent(context, event),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(context, eventController, event.id),
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreateEvent(BuildContext context) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventFormScreen()),
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEditEvent(BuildContext context, EventModel event) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
      );

      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _navigateToEventDetail(BuildContext context, EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  Future<void> _handleParticipation(
    BuildContext context,
    EventController eventController,
    EventModel event,
    String userId,
    bool isParticipating,
  ) async {
    try {
      if (isParticipating) {
        await eventController.leaveEvent(event.id, userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você saiu do evento')),
          );
        }
      } else {
        await eventController.joinEvent(event.id, userId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Você participará do evento!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EventController controller,
    String eventId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      try {
        await controller.deleteEvent(eventId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento excluído com sucesso')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
