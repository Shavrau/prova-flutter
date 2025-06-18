import 'package:flutter/material.dart';
import 'package:prova/features/events/event_form_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/models/event_model.dart';
import '../../../core/controllers/event_controller.dart';
import '../../../core/models/user_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        actions: [
          if (user?.isOrganization == true)
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
            Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, event.location),
            if (event.date != null)
              _buildDetailRow(Icons.calendar_today, _formatDate(event.date!)),
            if (event.description != null) ...[
              const SizedBox(height: 16),
              Text(
                'Descrição:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(event.description!),
            ],
            const SizedBox(height: 24),
            if (user?.isOrganization == true)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      () => _confirmDelete(context, eventController, event.id),
                  child: const Text('Excluir Evento'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text)],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _navigateToEditScreen(
    BuildContext context,
    EventModel event,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso')),
      );
    }
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso')),
      );
    }
  }
}
