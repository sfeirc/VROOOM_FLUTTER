import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load all required data in parallel
      final futures = await Future.wait([
        _apiService.getReservations(),
        _apiService.getCars(),
        _apiService.getUsers(),
      ]);
      
      setState(() {
        _reservations = futures[0] as List<Map<String, dynamic>>;
        _cars = futures[1] as List<Map<String, dynamic>>;
        _users = futures[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredReservations {
    if (_searchQuery.isEmpty) return _reservations;
    return _reservations.where((reservation) {
      final searchLower = _searchQuery.toLowerCase();
      final idUser = reservation['IdUser'] ?? '';
      final carInfo = '${reservation['NomMarque'] ?? ''} ${reservation['Modele'] ?? ''}'.toLowerCase();
      return idUser.toLowerCase().contains(searchLower) || carInfo.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une réservation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Reservations table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune réservation trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez une autre recherche',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                : Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Véhicule')),
                          DataColumn(label: Text('Date début')),
                          DataColumn(label: Text('Date fin')),
                          DataColumn(label: Text('Prix total')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _filteredReservations.map((reservation) => DataRow(
                          cells: [
                            DataCell(Text(_getUserName(reservation['IdUser']))),
                            DataCell(Text('${reservation['NomMarque'] ?? ''} ${reservation['Modele'] ?? ''}')),
                            DataCell(Text(_formatDate(reservation['DateDebut']))),
                            DataCell(Text(_formatDate(reservation['DateFin']))),
                            DataCell(Text('${reservation['MontantReservation']}€')),
                            DataCell(_buildStatusChip(reservation['Statut'])),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.amber),
                                  tooltip: 'Modifier',
                                  onPressed: () => _editReservation(reservation),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _deleteReservation(reservation),
                                ),
                              ],
                            )),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReservation,
        icon: const Icon(Icons.add_circle),
        label: const Text('Ajouter une réservation'),
        backgroundColor: Colors.amber.shade800,
        elevation: 4,
      ),
    );
  }

  String _getUserName(String? userId) {
    if (userId == null) return 'Client inconnu';
    final user = _users.firstWhere(
      (u) => u['IdUser'] == userId,
      orElse: () => {'Nom': 'Inconnu', 'Prenom': ''},
    );
    return '${user['Nom'] ?? ''} ${user['Prenom'] ?? ''}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'En attente':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'Confirmée':
        color = Colors.blue;
        label = 'Confirmée';
        break;
      case 'Terminée':
        color = Colors.green;
        label = 'Terminée';
        break;
      case 'Annulée':
        color = Colors.red;
        label = 'Annulée';
        break;
      default:
        color = Colors.grey;
        label = status ?? 'Inconnu';
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  void _createReservation() {
    final formKey = GlobalKey<FormState>();
    String? selectedUserId;
    String? selectedCarId;
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final montantController = TextEditingController();
    String? selectedStatus = 'En attente';
    Map<String, dynamic>? selectedCar;
    
    DateTime? startDate;
    DateTime? endDate;

    // Helper to calculate price
    void calculatePrice() {
      if (selectedCarId != null && startDate != null && endDate != null) {
        try {
          // Find the selected car
          final car = _cars.firstWhere((c) => c['IdVoiture'].toString() == selectedCarId);
          
          // Get the daily price
          final pricePerDay = double.tryParse(car['PrixLocation']?.toString() ?? '0') ?? 0.0;
          
          // Calculate number of days (including start and end dates)
          final days = endDate!.difference(startDate!).inDays + 1;
          
          if (days > 0) {
            // Calculate total price
            final totalPrice = pricePerDay * days;
            
            // Format with 2 decimal places
            setState(() {
              montantController.text = totalPrice.toStringAsFixed(2);
            });
            
            // Show feedback to user
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Durée sélectionnée: $days jours (${car['NomMarque']} ${car['Modele']} à $pricePerDay€/jour = ${totalPrice.toStringAsFixed(2)}€)',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            
            print('Price calculated: $pricePerDay/day × $days days = $totalPrice€');
          }
        } catch (e) {
          print('Error calculating price: $e');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_month, color: Colors.amber.shade800, size: 30),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter une nouvelle réservation',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sélectionnez le client, le véhicule et la période',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Form
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client & Car selection section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations de base',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Client selection
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Client',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.person),
                              ),
                              items: _users.map((user) => DropdownMenuItem(
                                value: user['IdUser'].toString(),
                                child: Text('${user['Nom'] ?? ''} ${user['Prenom'] ?? ''} (${user['Email'] ?? ''})'),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedUserId = value;
                                });
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un client' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Car selection
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Véhicule',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.directions_car),
                                helperText: 'Sélectionnez un véhicule disponible',
                              ),
                              items: _cars
                                  .where((car) => car['IdStatut'] == 'STAT001') // Only available cars
                                  .map((car) => DropdownMenuItem(
                                    value: car['IdVoiture'].toString(),
                                    child: Text(
                                      '${car['NomMarque'] ?? ''} ${car['Modele'] ?? ''} - ${car['PrixLocation']}€/jour',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCarId = value;
                                  selectedCar = _cars.firstWhere((car) => car['IdVoiture'] == value);
                                });
                                calculatePrice();
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un véhicule' : null,
                            ),
                            
                            // Car details if selected
                            if (selectedCar != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Véhicule sélectionné: ${selectedCar?['NomMarque'] ?? ''} ${selectedCar?['Modele'] ?? ''}, ${selectedCar?['Couleur'] ?? ''}, ${selectedCar?['NbPlaces'] ?? ''} places',
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Date and Price section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Période et tarification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Dates
                            Row(
                              children: [
                                // Start date
                                Expanded(
                                  child: TextFormField(
                                    controller: startDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Date de début',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      helperText: 'Premier jour de location (de 1 à 365 jours)',
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Colors.amber.shade800,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          startDate = date;
                                          startDateController.text = DateFormat('dd/MM/yyyy').format(date);
                                          
                                          // Clear end date if it's before the start date
                                          if (endDate != null && endDate!.isBefore(date)) {
                                            endDate = null;
                                            endDateController.text = '';
                                          }
                                        });
                                        calculatePrice();
                                      }
                                    },
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez sélectionner une date de début' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // End date
                                Expanded(
                                  child: TextFormField(
                                    controller: endDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Date de fin',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.event_available),
                                      helperText: 'Jusqu\'à 1 an de location maximum',
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      if (startDate == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.white),
                                                const SizedBox(width: 10),
                                                const Text('Veuillez d\'abord sélectionner une date de début'),
                                              ],
                                            ),
                                            backgroundColor: Colors.orange,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: endDate ?? startDate!.add(const Duration(days: 1)),
                                        firstDate: startDate!,
                                        lastDate: startDate!.add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Colors.amber.shade800,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          endDate = date;
                                          endDateController.text = DateFormat('dd/MM/yyyy').format(date);
                                        });
                                        calculatePrice();
                                      }
                                    },
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez sélectionner une date de fin' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Duration calculation
                            if (startDate != null && endDate != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.timer, color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Durée: ${endDate!.difference(startDate!).inDays + 1} jours',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Price and Status
                            Row(
                              children: [
                                // Price
                                Expanded(
                                  child: TextFormField(
                                    controller: montantController,
                                    decoration: InputDecoration(
                                      labelText: 'Prix total (€)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.euro),
                                      helperText: 'Calculé automatiquement',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un montant' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Status
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Statut',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.info_outline),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'En attente',
                                        child: Row(
                                          children: [
                                            Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('En attente'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Confirmée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.blue.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Confirmée'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Terminée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.done_all, color: Colors.green.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Terminée'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Annulée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Annulée'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedStatus = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Créer la réservation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Debug info
                            print('Creating reservation with:');
                            print('User ID: $selectedUserId (${selectedUserId.runtimeType})');
                            print('Car ID: $selectedCarId (${selectedCarId.runtimeType})');
                            
                            final reservationData = {
                              'IdUser': selectedUserId,
                              'IdVoiture': selectedCarId,
                              'DateDebut': startDate!.toIso8601String(),
                              'DateFin': endDate!.toIso8601String(),
                              'MontantReservation': double.parse(montantController.text),
                              'Statut': selectedStatus,
                            };
                            
                            await _apiService.createReservationAdmin(reservationData);
                            
                            // Close dialog and refresh data
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 16),
                                      const Text('Réservation créée avec succès'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 16),
                                      Expanded(child: Text('Erreur: ${e.toString()}')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editReservation(Map<String, dynamic> reservation) {
    final formKey = GlobalKey<FormState>();
    String? selectedUserId = reservation['IdUser'].toString();
    String? selectedCarId = reservation['IdVoiture'].toString();
    
    // Parse dates with null safety
    DateTime startDate = DateTime.parse(reservation['DateDebut']);
    DateTime endDate = DateTime.parse(reservation['DateFin']);
    
    final startDateController = TextEditingController(text: _formatDate(reservation['DateDebut']));
    final endDateController = TextEditingController(text: _formatDate(reservation['DateFin']));
    final montantController = TextEditingController(text: reservation['MontantReservation']?.toString() ?? '');
    String? selectedStatus = reservation['Statut'] ?? 'En attente';
    
    // Function to calculate price
    void calculatePrice() {
      if (selectedCarId != null && startDate != null && endDate != null) {
        try {
          // Find the selected car
          final car = _cars.firstWhere((c) => c['IdVoiture'].toString() == selectedCarId);
          
          // Get the daily price
          final pricePerDay = double.tryParse(car['PrixLocation']?.toString() ?? '0') ?? 0.0;
          
          // Calculate number of days (including start and end dates)
          final days = endDate.difference(startDate).inDays + 1;
          
          if (days > 0) {
            // Calculate total price
            final totalPrice = pricePerDay * days;
            
            // Format with 2 decimal places
            montantController.text = totalPrice.toStringAsFixed(2);
            
            print('Edit price calculated: $pricePerDay/day × $days days = $totalPrice€');
          }
        } catch (e) {
          print('Error calculating price in edit dialog: $e');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.edit_calendar, color: Colors.amber.shade800, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modifier la réservation',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${reservation['IdReservation']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client & Car selection section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations de base',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // User selection
                            DropdownButtonFormField<String>(
                              value: selectedUserId,
                              decoration: InputDecoration(
                                labelText: 'Client',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.person),
                              ),
                              items: _users.map((user) => DropdownMenuItem(
                                value: user['IdUser'].toString(),
                                child: Text('${user['Nom'] ?? ''} ${user['Prenom'] ?? ''} (${user['Email'] ?? ''})'),
                              )).toList(),
                              onChanged: (value) {
                                selectedUserId = value;
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un client' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Car selection
                            DropdownButtonFormField<String>(
                              value: selectedCarId,
                              decoration: InputDecoration(
                                labelText: 'Véhicule',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.directions_car),
                              ),
                              items: _cars.map((car) => DropdownMenuItem(
                                value: car['IdVoiture'].toString(),
                                child: Text('${car['NomMarque'] ?? ''} ${car['Modele'] ?? ''} - ${car['PrixLocation']}€/jour'),
                              )).toList(),
                              onChanged: (value) {
                                selectedCarId = value;
                                calculatePrice();
                              },
                              validator: (value) => value == null ? 'Veuillez sélectionner un véhicule' : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Date and Price section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Période et tarification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Dates
                            Row(
                              children: [
                                // Start date
                                Expanded(
                                  child: TextFormField(
                                    controller: startDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Date de début',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: startDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Colors.amber.shade800,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          startDate = date;
                                          startDateController.text = DateFormat('dd/MM/yyyy').format(date);
                                          
                                          // Clear end date if it's before the start date
                                          if (endDate.isBefore(date)) {
                                            endDate = date.add(const Duration(days: 1));
                                            endDateController.text = DateFormat('dd/MM/yyyy').format(endDate);
                                          }
                                          
                                          calculatePrice();
                                        });
                                      }
                                    },
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez sélectionner une date de début' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // End date
                                Expanded(
                                  child: TextFormField(
                                    controller: endDateController,
                                    decoration: InputDecoration(
                                      labelText: 'Date de fin',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.event_available),
                                      helperText: 'Jusqu\'à 1 an de location maximum',
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: endDate,
                                        firstDate: startDate,
                                        lastDate: startDate.add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Colors.amber.shade800,
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      
                                      if (date != null) {
                                        setState(() {
                                          endDate = date;
                                          endDateController.text = DateFormat('dd/MM/yyyy').format(date);
                                        });
                                        calculatePrice();
                                      }
                                    },
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez sélectionner une date de fin' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Duration calculation
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Durée: ${endDate.difference(startDate).inDays + 1} jours',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Price and Status
                            Row(
                              children: [
                                // Price
                                Expanded(
                                  child: TextFormField(
                                    controller: montantController,
                                    decoration: InputDecoration(
                                      labelText: 'Prix total (€)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.euro),
                                      helperText: 'Calculé automatiquement',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un montant' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Status
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Statut',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                      prefixIcon: const Icon(Icons.info_outline),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'En attente',
                                        child: Row(
                                          children: [
                                            Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('En attente'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Confirmée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.blue.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Confirmée'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Terminée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.done_all, color: Colors.green.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Terminée'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Annulée',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Annulée'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      selectedStatus = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Mettre à jour'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final reservationData = {
                              'IdUser': selectedUserId,
                              'IdVoiture': selectedCarId,
                              'DateDebut': startDate.toIso8601String(),
                              'DateFin': endDate.toIso8601String(),
                              'MontantReservation': double.parse(montantController.text),
                              'Statut': selectedStatus,
                            };
                            
                            await _apiService.updateReservation(reservation['IdReservation'], reservationData);
                            
                            // Close dialog and refresh data
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 16),
                                      const Text('Réservation mise à jour avec succès'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 16),
                                      Expanded(child: Text('Erreur: ${e.toString()}')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteReservation(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_busy, color: Colors.red.shade700, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Supprimer la réservation',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                  children: [
                    const TextSpan(text: 'Êtes-vous sûr de vouloir supprimer la réservation de '),
                    TextSpan(
                      text: _getUserName(reservation['IdUser']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' pour '),
                    TextSpan(
                      text: '${reservation['NomMarque'] ?? ''} ${reservation['Modele'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' ? Cette action est irréversible.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await _apiService.deleteReservation(reservation['IdReservation']);
                        
                        // Close dialog and refresh data
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Réservation supprimée avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 