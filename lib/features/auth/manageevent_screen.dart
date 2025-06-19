import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/event_model.dart';
import '../../core/controllers/event_controller.dart';
import '../../core/controllers/auth_controller.dart';
import 'createevent_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  State<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteEvent(EventController controller, String eventId) async {
    setState(() => _isLoading = true);
    try {
      await controller.deleteEvent(eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento excluído com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir evento: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditEvent(
    BuildContext context,
    EventModel event,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreateEventPage(
              isEditing: true, // Agora este parâmetro é reconhecido
              eventToEdit: event,
            ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventController = Provider.of<EventController>(context);
    final authController = Provider.of<AuthController>(context);
    final currentUserId = authController.currentUser?.uid;

    print('currentUserId: $currentUserId');

    if (currentUserId == null) {
      // Usuário ainda não carregado, exibe loading
      print('Usuário ainda não carregado, exibindo loading');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Eventos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar Novo Evento',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar eventos',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<EventModel>>(
                      stream: eventController.getEventsByUser(currentUserId ?? ''),
                      builder: (context, snapshot) {
                        print('Snapshot connectionState: \\${snapshot.connectionState}');
                        print('Snapshot hasError: \\${snapshot.hasError}');
                        print('Snapshot data: \\${snapshot.data}');
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar eventos: \\${snapshot.error}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final events = snapshot.data ?? [];
                        print('Eventos recebidos: \\${events.length}');
                        final filteredEvents =
                            events.where((event) {
                              final query = _searchQuery.toLowerCase();
                              final title = event.title ?? '';
                              final description = event.description ?? '';
                              final location = event.location ?? '';
                              return title.toLowerCase().contains(query) ||
                                  description.toLowerCase().contains(query) ||
                                  location.toLowerCase().contains(query);
                            }).toList();
                        print('Eventos filtrados: \\${filteredEvents.length}');

                        if (filteredEvents.isEmpty) {
                          print('Nenhum evento encontrado após filtro.');
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            print('Construindo card para evento: \\${event.id}');
                            return _buildEventCard(
                              context,
                              eventController,
                              event,
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note, size: 64),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhum evento encontrado'
                : 'Nenhum resultado para "${_searchQuery}"',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                ),
            child: const Text('Criar Primeiro Evento'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    EventController controller,
    EventModel event,
  ) {
    print('Event carregado: $event');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _navigateToEditEvent(context, event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(event.description ?? ''),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.location ?? '')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(event.dateTime ?? DateTime.now())),
                ],
              ),
              const SizedBox(height: 8),
              Text('Criado por: ${event.createdBy}'),
              const SizedBox(height: 4),
              Text('Criado em: ${DateFormat('dd/MM/yyyy HH:mm').format(event.createdAt ?? DateTime.now())}'),
              const SizedBox(height: 4),
              Text('Status: ${event.status}'),
              const SizedBox(height: 4),
              Text('Participantes: ${event.participants.length}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventMenu(
    BuildContext context,
    EventController controller,
    String eventId,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
      onSelected: (value) async {
        if (value == 'edit') {
          // Implemente a navegação para edição se necessário
        } else if (value == 'delete') {
          await _showDeleteConfirmation(context, controller, eventId);
        }
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    EventController controller,
    String eventId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text(
              'Tem certeza que deseja excluir este evento permanentemente?',
            ),
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
      await _deleteEvent(controller, eventId);
    }
  }
}
