import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/event_model.dart';
import '../../../core/controllers/event_controller.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/user_model.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);
    final authController = Provider.of<AuthController>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        centerTitle: true,
        actions: [
          if (user?.isOrganization == true && 
              eventController.isUserOrganizer(event, authController.currentUser?.uid ?? ''))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditScreen(context, event),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventHeader(context),
            const SizedBox(height: 24),
            _buildEventDetails(context),
            const SizedBox(height: 24),
            _buildDescriptionSection(context),
            const SizedBox(height: 24),
            _buildParticipationSection(context, eventController, authController, user),
            const SizedBox(height: 24),
            if (user?.isOrganization == true && 
                eventController.isUserOrganizer(event, authController.currentUser?.uid ?? ''))
              _buildDeleteButton(context, eventController),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(event.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.location_on,
              'Localização',
              event.location,
              Colors.red,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.calendar_today,
              'Data',
              DateFormat('dd/MM/yyyy').format(event.dateTime),
              Colors.blue,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.access_time,
              'Horário',
              DateFormat('HH:mm').format(event.dateTime),
              Colors.green,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.people,
              'Participantes',
              '${event.participants.length} pessoas',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    if (event.description.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationSection(
    BuildContext context,
    EventController eventController,
    AuthController authController,
    UserModel? user,
  ) {
    if (user?.isOrganization == true) return const SizedBox.shrink();
    
    final currentUserId = authController.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();
    
    final isParticipating = eventController.isUserParticipating(event, currentUserId);
    final isOrganizer = eventController.isUserOrganizer(event, currentUserId);
    
    if (isOrganizer) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Participar do Evento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleParticipation(
                  context,
                  eventController,
                  currentUserId,
                  isParticipating,
                ),
                icon: Icon(isParticipating ? Icons.exit_to_app : Icons.add),
                label: Text(isParticipating ? 'Sair do Evento' : 'Participar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isParticipating ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    EventController eventController,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmDelete(context, eventController),
        icon: const Icon(Icons.delete, color: Colors.white),
        label: const Text('Excluir Evento'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'finished':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ATIVO';
      case 'canceled':
        return 'CANCELADO';
      case 'finished':
        return 'FINALIZADO';
      default:
        return 'DESCONHECIDO';
    }
  }

  Future<void> _navigateToEditScreen(
    BuildContext context,
    EventModel event,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso')),
      );
    }
  }

  Future<void> _handleParticipation(
    BuildContext context,
    EventController eventController,
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

  Future<void> _confirmDelete(
    BuildContext context,
    EventController eventController,
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
        await eventController.deleteEvent(event.id);
        if (context.mounted) {
          Navigator.pop(context);
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
