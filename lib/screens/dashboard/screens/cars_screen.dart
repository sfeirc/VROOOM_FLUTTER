import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _cars = [];
  List<String> _brands = [];
  List<String> _types = [];
  
  // Filters
  String? _selectedBrand;
  String? _selectedType;
  String _searchQuery = '';

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    _loadData();
  }

  // Add debounce timer for search
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load cars with filters
      final cars = await _apiService.getCars(
        filters: {
          if (_selectedBrand != null) 'brand': _selectedBrand,
          if (_selectedType != null) 'type': _selectedType,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );
      
      // Load filter options with separate try-catch blocks
      List<Map<String, dynamic>> brands = [];
      List<Map<String, dynamic>> types = [];
      
      try {
        brands = await _apiService.getBrands();
      } catch (e) {
        print('Error loading brands: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des marques: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      
      try {
        types = await _apiService.getTypes();
      } catch (e) {
        print('Error loading types: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des types: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _brands = brands.map((b) => b['NomMarque'] as String).toList();
          _types = types.map((t) => t['NomType'] as String).toList();
          _cars = cars;
          _isLoading = false;
        });
        // Restart animation when data is loaded
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Helper function for search with debounce
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
      _loadData();
    });
  }

  // Reset all filters
  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedType = null;
      _searchQuery = '';
      if (_debounce?.isActive ?? false) _debounce!.cancel();
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filters
            Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Véhicules',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds, delay: 200.milliseconds).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher un véhicule...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          ),
                          style: GoogleFonts.poppins(),
                          onChanged: _onSearchChanged,
                        ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds, delay: 300.milliseconds).slideX(begin: -0.2, end: 0),
                      ),
                      const SizedBox(width: 16),
                      // Brand filter
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: DropdownButton<String>(
                          value: _selectedBrand,
                          hint: Text('Marque', style: GoogleFonts.poppins()),
                          underline: const SizedBox.shrink(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Toutes les marques', style: GoogleFonts.poppins()),
                            ),
                            ..._brands.map((brand) => DropdownMenuItem(
                              value: brand,
                              child: Text(brand, style: GoogleFonts.poppins()),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBrand = value;
                            });
                            _loadData();
                          },
                        ),
                      ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds, delay: 400.milliseconds).slideX(begin: -0.2, end: 0),
                      const SizedBox(width: 16),
                      // Type filter
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: DropdownButton<String>(
                          value: _selectedType,
                          hint: Text('Type', style: GoogleFonts.poppins()),
                          underline: const SizedBox.shrink(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade800),
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Tous les types', style: GoogleFonts.poppins()),
                            ),
                            ..._types.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins()),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                            _loadData();
                          },
                        ),
                      ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds, delay: 500.milliseconds).slideX(begin: -0.2, end: 0),
                      // Clear filters button
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.red.shade400),
                          tooltip: 'Effacer les filtres',
                          onPressed: _clearFilters,
                        ),
                      ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds, delay: 600.milliseconds).slideX(begin: -0.2, end: 0),
                    ],
                  ),
                ],
              ),
            ),
            
            // Cars table
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator().animate(autoPlay: true).scale(),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement des véhicules...',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate(autoPlay: true).fadeIn(delay: 300.milliseconds),
                        ],
                      ),
                    )
                  : _cars.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80, color: Colors.grey.shade400)
                                  .animate(autoPlay: true).scale(delay: 200.milliseconds),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun véhicule trouvé',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ).animate(autoPlay: true).fadeIn(delay: 400.milliseconds),
                              const SizedBox(height: 8),
                              Text(
                                'Essayez d\'autres filtres',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ).animate(autoPlay: true).fadeIn(delay: 500.milliseconds),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: Text('Réinitialiser les filtres', style: GoogleFonts.poppins()),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _clearFilters,
                              ).animate(autoPlay: true).fadeIn(delay: 600.milliseconds).scale(),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.all(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                                dataRowMaxHeight: 80,
                                dataRowMinHeight: 70,
                                columnSpacing: 16,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      'Image',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Marque',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Modèle',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Année',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Prix/Jour',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Statut',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: List.generate(_cars.length, (index) {
                                  final car = _cars[index];
                                  
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (index % 2 == 0) {
                                          return Colors.grey.shade50;
                                        }
                                        return Colors.white;
                                      },
                                    ),
                                    cells: [
                                      DataCell(_buildCarImage(car)),
                                      DataCell(
                                        Text(
                                          car['NomMarque'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          car['Modele'] ?? '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          car['Annee']?.toString() ?? '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${car['PrixLocation']}€/jour',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                      DataCell(_buildStatusChip(car['IdStatut'])),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              tooltip: 'Modifier',
                                              onPressed: () => _editCar(car),
                                            ).animate(autoPlay: true).scale(delay: (100 * index).milliseconds, duration: 200.milliseconds),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Supprimer',
                                              onPressed: () => _deleteCar(car),
                                            ).animate(autoPlay: true).scale(delay: (150 * index).milliseconds, duration: 200.milliseconds),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds).scale(delay: 200.milliseconds, duration: 400.milliseconds),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCar,
        icon: const Icon(Icons.add),
        label: Text('Ajouter un véhicule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ).animate(autoPlay: true)
        .fadeIn(delay: 600.milliseconds, duration: 500.milliseconds)
        .slideY(begin: 1, end: 0),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'STAT001':
        color = Colors.green.shade600;
        label = 'Disponible';
        break;
      case 'STAT002':
        color = Colors.orange.shade600;
        label = 'Loué';
        break;
      case 'STAT003':
        color = Colors.red.shade600;
        label = 'Maintenance';
        break;
      default:
        color = Colors.grey.shade600;
        label = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  void _createCar() {
    final formKey = GlobalKey<FormState>();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final colorController = TextEditingController();
    final doorsController = TextEditingController(text: "4");
    final seatsController = TextEditingController(text: "5");
    final powerController = TextEditingController();
    final imageUrlController = TextEditingController();
    String? selectedStatus = 'STAT001'; // Default to available
    String? selectedTransmission = 'Automatique';
    String? selectedEnergy = 'Essence';
    String? selectedType = _types.isNotEmpty ? _types[0] : null;

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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter un nouveau véhicule',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Remplissez les informations du véhicule',
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
                      // Basic info section
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
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _brands.isNotEmpty ? _brands[0] : null,
                                        decoration: InputDecoration(
                                          labelText: 'Marque',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.branding_watermark),
                                        ),
                                        items: _brands.map((brand) => DropdownMenuItem(
                                          value: brand,
                                          child: Text(brand),
                                        )).toList(),
                                        onChanged: (value) {
                                          brandController.text = value ?? '';
                                        },
                                        validator: (value) => value == null ? 'Veuillez sélectionner une marque' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: modelController,
                                        decoration: InputDecoration(
                                          labelText: 'Modèle',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.model_training),
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un modèle' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: colorController,
                                        decoration: InputDecoration(
                                          labelText: 'Couleur',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.color_lens),
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une couleur' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Right column
                                Expanded(
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: yearController,
                                        decoration: InputDecoration(
                                          labelText: 'Année',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.calendar_today),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une année' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: priceController,
                                        decoration: InputDecoration(
                                          labelText: 'Prix par jour (€)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.euro),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prix' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      DropdownButtonFormField<String>(
                                        value: selectedType,
                                        decoration: InputDecoration(
                                          labelText: 'Type de véhicule',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.category),
                                        ),
                                        items: _types.map((type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        )).toList(),
                                        onChanged: (value) {
                                          selectedType = value;
                                        },
                                        validator: (value) => value == null ? 'Veuillez sélectionner un type' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Image URL section
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
                              'Image du véhicule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: imageUrlController,
                              decoration: InputDecoration(
                                labelText: 'URL de l\'image',
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.image),
                                helperText: 'Laissez vide pour utiliser une image par défaut',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.preview),
                                  tooltip: 'Prévisualiser',
                                  onPressed: () {
                                    if (imageUrlController.text.isNotEmpty) {
                                      // Use our proxy to avoid CORS issues
                                      final proxyUrl = imageUrlController.text.startsWith('http')
                                        ? 'http://localhost:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrlController.text)}'
                                        : 'http://localhost:3000/${imageUrlController.text}';
                                      
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Prévisualisation de l\'image'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                height: 200,
                                                child: Image.network(
                                                  proxyUrl,
                                                  fit: BoxFit.contain,
                                                  headers: const {
                                                    'Accept': 'image/jpeg,image/png,image/gif,image/*',
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Image preview error: $error');
                                                    return Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                                        const SizedBox(height: 16),
                                                        const Text('Erreur de chargement de l\'image'),
                                                        Text(
                                                          error.toString().substring(0, error.toString().length > 100 
                                                            ? 100 
                                                            : error.toString().length),
                                                          style: const TextStyle(fontSize: 12),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Details section
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
                              'Caractéristiques',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedTransmission,
                                        decoration: InputDecoration(
                                          labelText: 'Boîte de vitesse',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        onChanged: (value) {
                                          selectedTransmission = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: doorsController,
                                        decoration: InputDecoration(
                                          labelText: 'Nombre de portes',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.door_front_door),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Right column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedEnergy,
                                        decoration: InputDecoration(
                                          labelText: 'Énergie',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.local_gas_station),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Essence', child: Text('Essence')),
                                          DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                                          DropdownMenuItem(value: 'Électrique', child: Text('Électrique')),
                                          DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                                        ],
                                        onChanged: (value) {
                                          selectedEnergy = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: seatsController,
                                        decoration: InputDecoration(
                                          labelText: 'Nombre de places',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.event_seat),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Power/Puissance field
                                      TextFormField(
                                        controller: powerController,
                                        decoration: InputDecoration(
                                          labelText: 'Puissance (ch)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.speed),
                                          helperText: 'Puissance moteur en chevaux',
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Status
                            DropdownButtonFormField<String>(
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
                              items: const [
                                DropdownMenuItem(value: 'STAT001', child: Text('Disponible')),
                                DropdownMenuItem(value: 'STAT002', child: Text('Loué')),
                                DropdownMenuItem(value: 'STAT003', child: Text('Maintenance')),
                              ],
                              onChanged: (value) {
                                selectedStatus = value;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Description
                            TextFormField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.description),
                              ),
                              maxLines: 3,
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
                      icon: const Icon(Icons.add),
                      label: const Text('Créer le véhicule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Create car data object
                            final carData = {
                              'NomMarque': brandController.text,
                              'Modele': modelController.text,
                              'Annee': int.parse(yearController.text),
                              'PrixLocation': double.parse(priceController.text),
                              'IdStatut': selectedStatus,
                              'BoiteVitesse': selectedTransmission,
                              'Energie': selectedEnergy,
                              'Couleur': colorController.text,
                              'NbPorte': int.parse(doorsController.text),
                              'NbPlaces': int.parse(seatsController.text),
                              'Puissance': powerController.text.isNotEmpty ? int.parse(powerController.text) : 100,
                              'Description': descriptionController.text.isNotEmpty 
                                ? descriptionController.text
                                : '${brandController.text} ${modelController.text}',
                              'Photo': imageUrlController.text,
                            };
                            
                            await _apiService.createCar(carData);
                            
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
                                      const Text('Véhicule créé avec succès'),
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

  void _editCar(Map<String, dynamic> car) {
    final formKey = GlobalKey<FormState>();
    final modelController = TextEditingController(text: car['Modele'] ?? '');
    final yearController = TextEditingController(text: car['Annee']?.toString() ?? '');
    final priceController = TextEditingController(text: car['PrixLocation']?.toString() ?? '');
    final powerController = TextEditingController(text: car['Puissance']?.toString() ?? '');
    final colorController = TextEditingController(text: car['Couleur'] ?? '');
    final doorsController = TextEditingController(text: car['NbPorte']?.toString() ?? '4');
    final seatsController = TextEditingController(text: car['NbPlaces']?.toString() ?? '5');
    final descriptionController = TextEditingController(text: car['Description'] ?? '');
    final imageUrlController = TextEditingController(text: car['Photo'] ?? '');
    String? selectedBrand = car['NomMarque'];
    String? selectedStatus = car['IdStatut'];
    String? selectedTransmission = car['BoiteVitesse'] ?? 'Automatique';
    String? selectedEnergy = car['Energie'] ?? 'Essence';

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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modifier ${car['NomMarque']} ${car['Modele']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${car['IdVoiture']}',
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
                
                // Form
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info section
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
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedBrand,
                                        decoration: InputDecoration(
                                          labelText: 'Marque',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.branding_watermark),
                                        ),
                                        items: _brands.map((brand) => DropdownMenuItem(
                                          value: brand,
                                          child: Text(brand),
                                        )).toList(),
                                        onChanged: (value) {
                                          selectedBrand = value;
                                        },
                                        validator: (value) => value == null ? 'Veuillez sélectionner une marque' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: modelController,
                                        decoration: InputDecoration(
                                          labelText: 'Modèle',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.model_training),
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un modèle' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: colorController,
                                        decoration: InputDecoration(
                                          labelText: 'Couleur',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.color_lens),
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une couleur' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Right column
                                Expanded(
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: yearController,
                                        decoration: InputDecoration(
                                          labelText: 'Année',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.calendar_today),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une année' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: priceController,
                                        decoration: InputDecoration(
                                          labelText: 'Prix par jour (€)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.euro),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prix' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      DropdownButtonFormField<String>(
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
                                        items: const [
                                          DropdownMenuItem(value: 'STAT001', child: Text('Disponible')),
                                          DropdownMenuItem(value: 'STAT002', child: Text('Loué')),
                                          DropdownMenuItem(value: 'STAT003', child: Text('Maintenance')),
                                        ],
                                        onChanged: (value) {
                                          selectedStatus = value;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Image URL section
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
                              'Image du véhicule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: imageUrlController,
                              decoration: InputDecoration(
                                labelText: 'URL de l\'image',
                                hintText: 'https://example.com/image.jpg',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(Icons.image),
                                helperText: 'Laissez vide pour utiliser une image par défaut',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.preview),
                                  tooltip: 'Prévisualiser',
                                  onPressed: () {
                                    if (imageUrlController.text.isNotEmpty) {
                                      // Use our proxy to avoid CORS issues
                                      final proxyUrl = imageUrlController.text.startsWith('http')
                                        ? 'http://localhost:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrlController.text)}'
                                        : 'http://localhost:3000/${imageUrlController.text}';
                                      
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Prévisualisation de l\'image'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                height: 200,
                                                child: Image.network(
                                                  proxyUrl,
                                                  fit: BoxFit.contain,
                                                  headers: const {
                                                    'Accept': 'image/jpeg,image/png,image/gif,image/*',
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Image preview error: $error');
                                                    return Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                                        const SizedBox(height: 16),
                                                        const Text('Erreur de chargement de l\'image'),
                                                        Text(
                                                          error.toString().substring(0, error.toString().length > 100 
                                                            ? 100 
                                                            : error.toString().length),
                                                          style: const TextStyle(fontSize: 12),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Details section
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
                              'Caractéristiques',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedTransmission,
                                        decoration: InputDecoration(
                                          labelText: 'Boîte de vitesse',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        onChanged: (value) {
                                          selectedTransmission = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: doorsController,
                                        decoration: InputDecoration(
                                          labelText: 'Nombre de portes',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.door_front_door),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Right column
                                Expanded(
                                  child: Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedEnergy,
                                        decoration: InputDecoration(
                                          labelText: 'Énergie',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.local_gas_station),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'Essence', child: Text('Essence')),
                                          DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                                          DropdownMenuItem(value: 'Électrique', child: Text('Électrique')),
                                          DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                                        ],
                                        onChanged: (value) {
                                          selectedEnergy = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: seatsController,
                                        decoration: InputDecoration(
                                          labelText: 'Nombre de places',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.event_seat),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: descriptionController,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.description),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ],
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Update car data
                            final carData = {
                              'NomMarque': selectedBrand,
                              'Modele': modelController.text,
                              'Annee': int.parse(yearController.text),
                              'PrixLocation': double.parse(priceController.text),
                              'IdStatut': selectedStatus,
                              'BoiteVitesse': selectedTransmission,
                              'Energie': selectedEnergy,
                              'Couleur': colorController.text,
                              'NbPorte': int.parse(doorsController.text),
                              'NbPlaces': int.parse(seatsController.text),
                              'Puissance': powerController.text.isNotEmpty ? int.parse(powerController.text) : 100,
                              'Description': descriptionController.text.isNotEmpty 
                                ? descriptionController.text
                                : '${selectedBrand} ${modelController.text}',
                              'Photo': imageUrlController.text,
                            };
                            
                            await _apiService.updateCar(car['IdVoiture'], carData);
                            
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
                                      const Text('Véhicule mis à jour avec succès'),
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

  void _deleteCar(Map<String, dynamic> car) {
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
                child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Supprimer le véhicule',
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
                    const TextSpan(text: 'Êtes-vous sûr de vouloir supprimer '),
                    TextSpan(
                      text: '${car['NomMarque']} ${car['Modele']}',
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
                        await _apiService.deleteCar(car['IdVoiture']);
                        
                        // Close dialog and refresh data
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Véhicule supprimé avec succès'),
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

  Widget _buildCarImage(Map<String, dynamic> car) {
    if (car['Photo'] == null || car['Photo'].toString().trim().isEmpty) {
      return _buildPlaceholderImage(car);
    }
    
    final imageUrl = _getImageUrl(car['Photo'].toString());
    print('Final image URL: $imageUrl');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder shown while loading
            Center(
              child: _buildPlaceholderImage(car),
            ),
            // Actual image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              headers: const {
                'Accept': 'image/jpeg,image/png,image/gif,image/*',
              },
              cacheWidth: 100, // Smaller size to improve performance
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: ${car['Photo']} - $error');
                return _buildPlaceholderImage(car);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(Map<String, dynamic> car) {
    // Get make and model to display
    final make = car['NomMarque'] as String? ?? '';
    final model = car['Modele'] as String? ?? '';
    final shortName = make.isNotEmpty ? make[0] + (model.isNotEmpty ? model[0] : '') : '?';
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shortName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (make.isNotEmpty || model.isNotEmpty)
              Text(
                make.isNotEmpty ? make : model,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black26,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String imageUrl) {
    // Log the original URL for debugging
    print('Processing image URL: $imageUrl');
    
    // If URL is empty or null, return a placeholder
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'http://localhost:3000/api/assets/images/default-car.jpg';
    }
    
    // Handle motor1.com URLs through our proxy to fix CORS issues
    if (imageUrl.contains('cdn.motor1.com')) {
      print('Using proxy for motor1.com URL: $imageUrl');
      return 'http://localhost:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
    }
    // Handle other external URLs
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('Using proxy for external URL: $imageUrl');
      return 'http://localhost:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
    } 
    // Handle local assets
    else if (imageUrl.startsWith('assets/')) {
      print('Using local asset path: $imageUrl');
      return 'http://localhost:3000/$imageUrl';
    } 
    // Default case
    else {
      print('Using default path: $imageUrl');
      return 'http://localhost:3000/$imageUrl';
    }
  }
} 