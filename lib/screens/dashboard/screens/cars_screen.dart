// Importations nécessaires
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// Écran des voitures
class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});
// Crée un état pour l'écran des voitures 
  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

// État pour l'écran des voitures
class _CarsScreenState extends State<CarsScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _cars = [];
  List<String> _brands = [];
  List<String> _types = [];
  
  // Filtres
  String? _selectedBrand;
  String? _selectedType;
  String _searchQuery = '';

  // Contrôleur d'animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs pour les champs de formulaire
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController powerController = TextEditingController();
  final TextEditingController doorsController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialise le contrôleur d'animation
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

  // Ajoute un délai pour la recherche
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
      
      // Charge les voitures avec les filtres
      final cars = await _apiService.getCars(
        filters: {
          if (_selectedBrand != null) 'brand': _selectedBrand,
          if (_selectedType != null) 'type': _selectedType,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );
      
      // Charge les options de filtre avec des blocs try-catch séparés
      List<Map<String, dynamic>> brands = [];
      List<Map<String, dynamic>> types = [];
      
      // Charge les marques
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
      
      // Charge les types
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
      // Met à jour l'état de l'écran
      if (mounted) {
        setState(() {
          _brands = brands.map((b) => b['NomMarque'] as String).toList();
          _types = types.map((t) => t['NomType'] as String).toList();
          _cars = cars;
          _isLoading = false;
        });
        // Redémarre l'animation lorsque les données sont chargées
        _animationController.reset();
        _animationController.forward();
      }
      // Gère les erreurs lors du chargement des données
    } catch (e) {
      print('Erreur dans _loadData: $e');
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

  // Fonction d'assistance pour la recherche avec délai
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
      _loadData();
    });
  }

  // Réinitialise tous les filtres
  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedType = null;
      _searchQuery = '';
      if (_debounce?.isActive ?? false) _debounce!.cancel();
    });
    _loadData();
  }// Construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec filtres
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
              // Contenu de l'en-tête
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
            
            // Tableau des voitures
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
                    // Si les voitures sont chargées
                  : _cars.isEmpty
                      ? Center(
                          // Si aucun véhicule n'est trouvé
                          child: Column(
                            // Centre le contenu
                            mainAxisAlignment: MainAxisAlignment.center,
                            // Contenu de la colonne
                            children: [
                              // Icône de recherche non trouvée
                              Icon(Icons.search_off, size: 80, color: Colors.grey.shade400)
                              // Fait apparaître l'icône avec un délai
                              .animate(autoPlay: true).scale(delay: 200.milliseconds),
                              // Espacement vertical
                              const SizedBox(height: 16),
                              // Texte principal
                              Text(
                                // Texte principal
                                'Aucun véhicule trouvé',
                                // Style du texte
                                style: GoogleFonts.poppins( 
                                  // Taille de la police  
                                  fontSize: 22,
                                  // Poids de la police
                                  fontWeight: FontWeight.bold,
                                  // Couleur du texte
                                  color: Colors.grey.shade700,
                                  // Espacement vertical
                                ),
                              ).animate(autoPlay: true).fadeIn(delay: 400.milliseconds),
                              // Espacement vertical
                              const SizedBox(height: 8),
                              Text(
                                // Texte principal
                                'Essayez d\'autres filtres',
                                // Style du texte
                                style: GoogleFonts.poppins(
                                  // Taille de la police
                                  fontSize: 16,
                                  // Couleur du texte
                                  color: Colors.grey.shade600,
                                ),
                              ).animate(autoPlay: true).fadeIn(delay: 500.milliseconds),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                // Icône du bouton
                                icon: const Icon(Icons.refresh),
                                // Texte du bouton
                                label: Text('Réinitialiser les filtres', style: GoogleFonts.poppins()),
                                // Style du bouton
                                style: ElevatedButton.styleFrom(
                                  // Couleur du texte
                                  foregroundColor: Colors.white,
                                  // Couleur de fond
                                  backgroundColor: Colors.blue.shade600,
                                  // Padding
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  // Élévation
                                  elevation: 4,
                                  // Forme du bouton
                                  shape: RoundedRectangleBorder(
                                    // Rayon de la bordure
                                    borderRadius: BorderRadius.circular(12),  
                                  ),
                                ),
                                // Action du bouton
                                onPressed: _clearFilters,
                                // Animation
                              ).animate(autoPlay: true).fadeIn(delay: 600.milliseconds).scale(),
                              // Espacement vertical
                            ],
                          ),
                        )
                        // Si les voitures sont vides
                      : Card(
                          // Élévation
                          elevation: 6,
                          // Forme du carton
                          shape: RoundedRectangleBorder(
                            // Rayon de la bordure
                            borderRadius: BorderRadius.circular(16),
                          ),
                          // Marge
                          margin: const EdgeInsets.all(16),
                          child: ClipRRect(
                            // Rayon de la bordure
                            borderRadius: BorderRadius.circular(16),
                            child: SingleChildScrollView(
                              child: DataTable(
                                // Couleur de la ligne d'en-tête
                                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                                // Hauteur maximale de la ligne de données
                                dataRowMaxHeight: 80,
                                // Hauteur minimale de la ligne de données
                                dataRowMinHeight: 70,
                                // Espacement entre les colonnes
                                columnSpacing: 16,
                                // Colonnes
                                columns: [
                                  // Colonnes
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Image',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Marque',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Modèle',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Année',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Prix/Jour',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    // Texte de la colonne
                                    label: Text(
                                      // Texte de la colonne
                                      'Statut',
                                      // Style du texte
                                      style: GoogleFonts.poppins(
                                        // Poids de la police
                                        fontWeight: FontWeight.bold,
                                        // Couleur du texte
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
                                  // Génère les lignes du tableau
                                  final car = _cars[index];
                                  // Retourne les lignes du tableau
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color>(
                                      // Génère les lignes du tableau
                                      (Set<MaterialState> states) {
                                        if (index % 2 == 0) {
                                          // Couleur de la ligne
                                          return Colors.grey.shade50;
                                        }
                                        // Couleur de la ligne
                                        return Colors.white;
                                      },
                                    ),
                                    cells: [
                                      // Génère les cellules du tableau
                                      DataCell(_buildCarImage(car)),
                                      // Génère les cellules du tableau
                                      DataCell(
                                        Text(
                                          car['NomMarque'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        // Génère les cellules du tableau
                                        Text(
                                          car['Modele'] ?? '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      DataCell(
                                        // Génère les cellules du tableau
                                        Text(
                                          car['Annee']?.toString() ?? '',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                      DataCell(
                                        // Génère les cellules du tableau
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
                                        // Génère les cellules du tableau
                                        Row(  
                                          // Taille de la ligne
                                          mainAxisSize: MainAxisSize.min,
                                          // Contenu de la ligne
                                          children: [
                                            // Icône du bouton
                                            IconButton(
                                              // Icône du bouton
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              // Tooltip
                                              tooltip: 'Modifier',
                                              // Action du bouton
                                              onPressed: () => _editCar(car),
                                            ).animate(autoPlay: true).scale(delay: (100 * index).milliseconds, duration: 200.milliseconds),
                                            // Icône du bouton
                                            IconButton(
                                              // Icône du bouton
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              // Tooltip
                                              tooltip: 'Supprimer',
                                              // Action du bouton
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
                          // Animation
                        ).animate(autoPlay: true).fadeIn(duration: 600.milliseconds).scale(delay: 200.milliseconds, duration: 400.milliseconds),
            ),
          ],
        ),
      ),
      // Bouton flottant
      floatingActionButton: FloatingActionButton.extended(
        // Action du bouton
        onPressed: _createCar,
        // Icône du bouton
        icon: const Icon(Icons.add),
        // Texte du bouton
        label: Text('Ajouter un véhicule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        // Couleur de fond
        backgroundColor: Colors.blue.shade700,
        // Élévation
        elevation: 4,
      ).animate(autoPlay: true)
        // Animation
        .fadeIn(delay: 600.milliseconds, duration: 500.milliseconds)
        // Animation
        .slideY(begin: 1, end: 0),
    );
  }

  // Construit un chip de statut
  Widget _buildStatusChip(String? status) {
    Color color;
    String label;

    // Switch pour le statut
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

    // Retourne un container avec le statut
    return Container(
      // Padding
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      // Décoration
      decoration: BoxDecoration(
        // Couleur de fond
        color: color.withOpacity(0.15),
        // Rayon de la bordure
        borderRadius: BorderRadius.circular(30),
        // Bordure
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
    // Clé du formulaire
    final formKey = GlobalKey<FormState>();
    // Contrôleur de marque
    final brandController = TextEditingController();
    // Contrôleur de modèle
    final modelController = TextEditingController();
    // Contrôleur d'année
    final yearController = TextEditingController();
    // Contrôleur de prix
    final priceController = TextEditingController();
    // Contrôleur de couleur
    final colorController = TextEditingController();
    // Contrôleur de portes
    final doorsController = TextEditingController(text: "4");
    // Contrôleur de sièges
    final seatsController = TextEditingController(text: "5");
    // Contrôleur de puissance
    final powerController = TextEditingController();
    // Contrôleur de l'URL de l'image
    final imageUrlController = TextEditingController();
    // Statut sélectionné
    String? selectedStatus = 'STAT001'; // Disponible
    // Transmission sélectionnée
    String? selectedTransmission = 'Automatique';
    // Énergie sélectionnée
    String? selectedEnergy = 'Essence';
    // Type sélectionné
    String? selectedType = _types.isNotEmpty ? _types[0] : null;

    // Affiche le dialogue
    showDialog(
      context: context,
      builder: (context) => Dialog(
        // Forme du dialogue
        shape: RoundedRectangleBorder(
          // Rayon de la bordure
          borderRadius: BorderRadius.circular(20),
        ),
        // Élévation
        elevation: 0,
        // Couleur de fond
        backgroundColor: Colors.transparent,
        child: Container(
          // Largeur du dialogue
          width: MediaQuery.of(context).size.width * 0.6,
          // Padding
          padding: const EdgeInsets.all(30),
          // Décoration
          decoration: BoxDecoration(
            // Couleur de fond
            color: Colors.white,
            // Forme du dialogue
            shape: BoxShape.rectangle,
            // Rayon de la bordure
            borderRadius: BorderRadius.circular(20),
            // Ombre
            boxShadow: [
              // Ombre
              BoxShadow(
                // Couleur de l'ombre
                color: Colors.black26,
                // Rayon de l'ombre
                blurRadius: 15.0,
                // Décalage de l'ombre
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          // Contenu du dialogue
          child: SingleChildScrollView(
            child: Column(
              // Taille de la colonne
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  // Padding
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // Décoration
                  decoration: BoxDecoration(
                    // Bordure
                    border: Border(
                      // Bordure
                      bottom: BorderSide(
                        // Couleur de la bordure
                        color: Colors.grey.shade200,
                        // Largeur de la bordure
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    // Contenu de la ligne
                    children: [
                      // Contenu du conteneur
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(12),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.blue.shade50,
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Contenu du conteneur
                        child: const Icon(Icons.directions_car, color: Colors.blue, size: 30),
                      ),
                      // Espacement horizontal
                      const SizedBox(width: 16),
                      const Column(
                        // Alignement du texte
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Contenu de la colonne
                        children: [
                          // Texte
                          Text(
                            // Texte
                            'Ajouter un nouveau véhicule',
                            // Style du texte
                            style: TextStyle(
                              // Taille de la police
                              fontSize: 24,
                              // Poids de la police
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Espacement vertical
                          SizedBox(height: 4),
                          // Texte
                          Text(
                            // Texte
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
                // Espacement vertical
                const SizedBox(height: 30),
                
                // Form
                Form(
                  // Clé du formulaire
                  key: formKey,
                  // Contenu du formulaire
                  child: Column(
                    // Taille de la colonne
                    mainAxisSize: MainAxisSize.min,
                    // Alignement du texte  
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info section
                      Container(  
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(12),
                          // Bordure
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Contenu de la colonne
                          children: [
                            // Texte
                            Text(
                              // Texte
                              'Informations de base',
                              // Style du texte
                              style: TextStyle(
                                // Taille de la police
                                fontSize: 16,
                                // Poids de la police
                                fontWeight: FontWeight.bold,
                                // Couleur du texte
                                color: Colors.blue.shade800,
                              ),
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              // Alignement du texte
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // Contenu de la colonne
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    // Contenu de la colonne
                                    children: [
                                      // Bouton de sélection
                                      DropdownButtonFormField<String>(
                                        // Valeur sélectionnée
                                        value: _brands.isNotEmpty ? _brands[0] : null,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Marque',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.branding_watermark),
                                          // Couleur de fond
                                        ),
                                        items: _brands.map((brand) => DropdownMenuItem(
                                          // Valeur sélectionnée
                                          value: brand,
                                          // Contenu du menu
                                          child: Text(brand),
                                        )).toList(),
                                        // Action du bouton
                                        onChanged: (value) {
                                          // Texte du contrôleur
                                          brandController.text = value ?? '';
                                        },
                                        // Validation
                                        validator: (value) => value == null ? 'Veuillez sélectionner une marque' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: modelController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Modèle',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.model_training),
                                        ),
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un modèle' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: colorController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Couleur',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.color_lens),
                                        ),
                                        // Validation
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une couleur' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Espacement horizontal
                                const SizedBox(width: 16),
                                
                                // Right column
                                Expanded(
                                  child: Column(
                                    // Contenu de la colonne
                                    children: [
                                      // Texte
                                      TextFormField(
                                        // Contrôleur
                                        controller: yearController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          labelText: 'Année',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.calendar_today),
                                        ),
                                        // Type de clavier
                                        keyboardType: TextInputType.number,
                                        // Validation
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une année' : null,
                                      ),
                                      // Espacement vertical
                                      const SizedBox(height: 16),
                                      
                                      // Texte
                                      TextFormField(
                                        // Contrôleur
                                        controller: priceController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          labelText: 'Prix par jour (€)',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.euro),
                                        ),
                                        keyboardType: TextInputType.number,
                                        // Validation
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prix' : null,
                                      ),
                                      // Espacement vertical
                                      const SizedBox(height: 16),
                                      
                                      // Type de véhicule
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
                                      const SizedBox(height: 16),
                                      
                                      // Transmission
                                      DropdownButtonFormField<String>(
                                        // Valeur sélectionnée
                                        value: selectedTransmission,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Boîte de vitesse',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        // Items
                                        items: const [
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        // Action du bouton
                                        onChanged: (value) {
                                          // Texte du contrôleur
                                          selectedTransmission = value;
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
                      
                      // Espacement vertical  
                      const SizedBox(height: 20),
                      
                      // Container
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Contenu de la colonne
                          children: [
                            // Texte
                            Text(
                              'Image du véhicule',
                              // Style du texte
                              style: TextStyle(
                                // Taille de la police
                                fontSize: 16,
                                // Poids de la police
                                fontWeight: FontWeight.bold,
                                // Couleur du texte
                                color: Colors.blue.shade800,
                              ),
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Texte
                            TextFormField(
                              // Contrôleur
                              controller: imageUrlController,
                              // Décoration
                              decoration: InputDecoration(
                                // Texte du label
                                labelText: 'URL de l\'image',
                                // Texte du hint
                                hintText: 'https://example.com/image.jpg',
                                // Bordure
                                border: OutlineInputBorder(
                                  // Rayon de la bordure
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Couleur de fond
                                fillColor: Colors.white,
                                // Couleur de fond
                                filled: true,
                                // Icône
                                prefixIcon: const Icon(Icons.image),
                                // Texte du helper
                                helperText: 'Laissez vide pour utiliser une image par défaut',
                                // Icône
                                suffixIcon: IconButton(
                                  // Icône
                                  icon: const Icon(Icons.preview),
                                  // Texte du tooltip
                                  tooltip: 'Prévisualiser',
                                  onPressed: () {
                                    // Si le contrôleur n'est pas vide
                                    if (imageUrlController.text.isNotEmpty) {
                                      // Utiliser notre proxy pour éviter les problèmes de CORS
                                      final proxyUrl = imageUrlController.text.startsWith('http')
                                        ? 'http://172.16.199.254:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrlController.text)}'
                                        : 'http://172.16.199.254:3000/${imageUrlController.text}';
                                      
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          // Texte
                                          title: const Text('Prévisualisation de l\'image'),
                                          // Contenu de la colonne
                                          content: Column(
                                            // Taille de la colonne
                                            mainAxisSize: MainAxisSize.min,
                                            // Contenu de la colonne
                                            children: [
                                              // SizedBox
                                              SizedBox(
                                                // Largeur
                                                width: 300,
                                                // Hauteur
                                                height: 200,
                                                child: Image.network(
                                                  // URL
                                                  proxyUrl,
                                                  // Fit
                                                  fit: BoxFit.contain,
                                                  // Headers
                                                  headers: const {
                                                    'Accept': 'image/jpeg,image/png,image/gif,image/*',
                                                  },
                                                  // Loading builder
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    // Si le chargement est null
                                                    if (loadingProgress == null) return child;
                                                    // Retourner un Center
                                                    return Center(
                                                      // Retourner un CircularProgressIndicator
                                                      child: CircularProgressIndicator(
                                                        // Valeur
                                                        value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    // Afficher l'erreur
                                                    print('Image preview error: $error');
                                                    // Retourner un Column
                                                    return Column(
                                                      // Taille de la colonne
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // Icône
                                                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                                        // Espacement vertical
                                                        const SizedBox(height: 16),
                                                        // Texte
                                                        const Text('Erreur de chargement de l\'image'),
                                                        // Texte
                                                        Text(
                                                          // Erreur
                                                          error.toString().substring(0, error.toString().length > 100 
                                                            ? 100 
                                                            : error.toString().length),
                                                          // Style du texte
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
                                          // Actions
                                          actions: [
                                            // Texte
                                            TextButton(
                                              // Action du bouton
                                              onPressed: () => Navigator.pop(context),
                                              // Texte
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
                      
                      // Espacement vertical
                      const SizedBox(height: 20),
                      
                      // Container
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // Contenu de la colonne
                          children: [
                            // Texte
                            Text(
                              'Caractéristiques',
                              // Style du texte
                              style: TextStyle(
                                // Taille de la police
                                fontSize: 16,
                                // Poids de la police
                                fontWeight: FontWeight.bold,
                                // Couleur du texte
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Two columns layout
                            Row(
                              // Alignement du texte
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // Contenu de la colonne
                              children: [
                                // Left column
                                Expanded(
                                  child: Column(
                                    // Contenu de la colonne
                                    children: [
                                      // DropdownButtonFormField
                                      DropdownButtonFormField<String>(
                                        // Valeur sélectionnée
                                        value: selectedEnergy,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Énergie',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.local_gas_station),
                                        ),
                                        // Items
                                        items: const [
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Essence', child: Text('Essence')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Électrique', child: Text('Électrique')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                                        ],
                                        onChanged: (value) {
                                          // Texte du contrôleur
                                          selectedEnergy = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: doorsController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Nombre de portes',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
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
                                    // Contenu de la colonne
                                    children: [
                                      // DropdownButtonFormField
                                      DropdownButtonFormField<String>(
                                        // Valeur sélectionnée
                                        value: selectedTransmission,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Boîte de vitesse',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        // Items
                                        items: const [
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        // Action du bouton
                                        onChanged: (value) {
                                          // Texte du contrôleur
                                          selectedTransmission = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: seatsController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Nombre de places',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.event_seat),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // puissance
                                      TextFormField(
                                        // Contrôleur
                                        controller: powerController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          labelText: 'Puissance (ch)',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.speed),
                                          // Texte du helper
                                          helperText: 'Puissance moteur en chevaux',
                                        ),
                                        // Type de clavier
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Status
                            DropdownButtonFormField<String>(
                              // Valeur sélectionnée
                              value: selectedStatus,
                              // Décoration
                              decoration: InputDecoration(
                                // Texte du label
                                labelText: 'Statut',
                                // Bordure
                                border: OutlineInputBorder(
                                  // Rayon de la bordure
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Couleur de fond
                                fillColor: Colors.white,
                                // Couleur de fond
                                filled: true,
                                // Icône
                                prefixIcon: const Icon(Icons.info_outline),
                              ),
                              // Items
                              items: const [
                                // DropdownMenuItem
                                DropdownMenuItem(value: 'STAT001', child: Text('Disponible')),
                                // DropdownMenuItem
                                DropdownMenuItem(value: 'STAT002', child: Text('Loué')),
                                // DropdownMenuItem
                                DropdownMenuItem(value: 'STAT003', child: Text('Maintenance')),
                              ],
                              onChanged: (value) {
                                selectedStatus = value;
                              },
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Description
                            TextFormField(
                              // Contrôleur
                              controller: descriptionController,
                              // Décoration
                              decoration: InputDecoration(
                                labelText: 'Description',
                                // Bordure
                                border: OutlineInputBorder(
                                  // Rayon de la bordure
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Couleur de fond
                                fillColor: Colors.white,
                                // Couleur de fond
                                filled: true,
                                // Icône
                                prefixIcon: const Icon(Icons.description),
                              ),
                              // Nombre de lignes
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
                  // Alignement du texte
                  mainAxisAlignment: MainAxisAlignment.end,
                  // Contenu de la colonne
                  children: [
                    // Texte
                    TextButton(
                      // Style
                      style: TextButton.styleFrom(
                        // Padding
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      // Action du bouton
                      onPressed: () => Navigator.pop(context),
                      // Texte
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      // Icône
                      icon: const Icon(Icons.add),
                      // Texte
                      label: const Text('Créer le véhicule'),
                      // Style
                      style: ElevatedButton.styleFrom(
                        // Couleur de fond
                        backgroundColor: Colors.blue,
                        // Couleur du texte
                        foregroundColor: Colors.white,
                        // Padding
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        // Bordure
                        shape: RoundedRectangleBorder(
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Action du bouton
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Créer un objet de données de voiture
                            final carData = {
                              'NomMarque': brandController.text,
                              'Modele': modelController.text,
                              'Annee': int.parse(yearController.text),
                              'PrixLocation': double.parse(priceController.text),
                              'IdStatut': selectedStatus,
                              'BoiteVitesse': selectedTransmission,
                              'Energie': selectedEnergy,
                              'Type': selectedType,
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
                            
                            // Fermer le dialogue et actualiser les données
                            if (mounted) {
                              // Fermer le dialogue
                              Navigator.pop(context);
                              // Actualiser les données
                              _loadData();
                              // Afficher un SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  // Contenu
                                  content: Row(
                                    // Contenu de la colonne
                                    children: [
                                      // Icône
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      // Espacement horizontal
                                      const SizedBox(width: 16),
                                      // Texte
                                      const Text('Véhicule créé avec succès'),
                                    ],
                                  ),
                                  // Couleur de fond
                                  backgroundColor: Colors.green,
                                  // Comportement
                                  behavior: SnackBarBehavior.floating,
                                  // Bordure
                                  shape: RoundedRectangleBorder(
                                    // Rayon de la bordure
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                            // Afficher un SnackBar
                          } catch (e) {
                            final errorMessage = 'Erreur: ${e.toString()}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
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
      ),
    );
  }

  void _editCar(Map<String, dynamic> car) {
    // Clé du formulaire
    final formKey = GlobalKey<FormState>();
    // Contrôleur du modèle
    final modelController = TextEditingController(text: car['Modele'] ?? '');
    // Contrôleur de l'année
    final yearController = TextEditingController(text: car['Annee']?.toString() ?? '');
    // Contrôleur du prix
    final priceController = TextEditingController(text: car['PrixLocation']?.toString() ?? '');
    // Contrôleur de la puissance
    final powerController = TextEditingController(text: car['Puissance']?.toString() ?? '');
    // Contrôleur de la couleur
    final colorController = TextEditingController(text: car['Couleur'] ?? '');
    // Contrôleur du nombre de portes
    final doorsController = TextEditingController(text: car['NbPorte']?.toString() ?? '4');
    // Contrôleur du nombre de places
    final seatsController = TextEditingController(text: car['NbPlaces']?.toString() ?? '5');
    // Contrôleur de la description
    final descriptionController = TextEditingController(text: car['Description'] ?? '');
    // Contrôleur de l'URL de l'image
    final imageUrlController = TextEditingController(text: car['Photo'] ?? '');
    // Marque sélectionnée
    String? selectedBrand = car['NomMarque'];
    // Statut sélectionné
    String? selectedStatus = car['IdStatut'];
    // Type sélectionné
    String? selectedType = car['Type'];
    // Transmission sélectionnée
    String? selectedTransmission = car['BoiteVitesse'] ?? 'Automatique';
    // Énergie sélectionnée
    String? selectedEnergy = car['Energie'] ?? 'Essence';
    // Afficher le dialogue 
    showDialog(
      context: context,
      builder: (context) => Dialog(
        // Forme
        shape: RoundedRectangleBorder(
          // Rayon de la bordure
          borderRadius: BorderRadius.circular(20),
        ),
        // Elevation
        elevation: 0,
        // Couleur de fond
        backgroundColor: Colors.transparent,
        child: Container(
          // Largeur
          width: MediaQuery.of(context).size.width * 0.6,
          // Padding
          padding: const EdgeInsets.all(30),
          // Décoration
          decoration: BoxDecoration(
            // Couleur de fond
            color: Colors.white,
            // Forme
            shape: BoxShape.rectangle,
            // Rayon de la bordure
            borderRadius: BorderRadius.circular(20),
            // Ombre
            boxShadow: [
              BoxShadow(
                // Couleur
                color: Colors.black26,
                // Rayon de l'ombre
                blurRadius: 15.0,
                // Décalage
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            // Contenu
            child: Column(
              // Taille de l'axe principal
              mainAxisSize: MainAxisSize.min,
              // Contenu de la colonne
              children: [
                // Header
                Container(
                  // Padding
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  // Décoration
                  decoration: BoxDecoration(
                    // Bordure
                    border: Border(
                      bottom: BorderSide(
                        // Couleur
                        color: Colors.grey.shade200,
                        // Largeur
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    // Contenu de la colonne
                    children: [
                      // Contenu
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(12),
                        // Décoration
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        // Alignement du texte
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Contenu de la colonne
                        children: [
                          // Texte
                          Text(
                            'Modifier ${car['NomMarque']} ${car['Modele']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Espacement vertical
                          const SizedBox(height: 4),
                          // Texte
                          Text(
                            // Texte
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
                // Espacement vertical
                const SizedBox(height: 30),
                // Forme
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section des informations de base
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(12),
                          // Bordure
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texte
                            Text(
                              'Informations de base',
                              // Style
                              style: TextStyle(
                                // Taille
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Layout
                            Row(
                              // Alignement du texte
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Colonne gauche
                                Expanded(
                                  child: Column(
                                    // Contenu de la colonne
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
                                
                                // Colonne droite
                                Expanded(
                                  // Colonne
                                  child: Column(
                                    // Contenu de la colonne
                                    children: [
                                      // Texte
                                      TextFormField(
                                        // Contrôleur
                                        controller: yearController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Année',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.calendar_today),
                                        ),
                                        // Type de clavier
                                        keyboardType: TextInputType.number,
                                        // Validation
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer une année' : null,
                                      ),
                                      // Espacement vertical
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: priceController,
                                        // Décoration
                                        decoration: InputDecoration(
                                            // Texte
                                          labelText: 'Prix par jour (€)',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.euro),
                                        ),
                                        // Type de clavier
                                        keyboardType: TextInputType.number,
                                        // Validation
                                        validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer un prix' : null,
                                      ),
                                      // Espacement vertical
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
                                      const SizedBox(height: 16),
                                      
                                      // Transmission
                                      DropdownButtonFormField<String>(
                                        // Valeur sélectionnée
                                        value: selectedTransmission,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte du label
                                          labelText: 'Boîte de vitesse',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        // Items
                                        items: const [
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          // DropdownMenuItem
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        // Action du bouton
                                        onChanged: (value) {
                                          // Texte du contrôleur
                                          selectedTransmission = value;
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
                      
                      // Espacement vertical
                      const SizedBox(height: 20),
                      
                      // Section d'URL de l'image
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(12),
                          // Bordure
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texte
                            Text(
                              'Image du véhicule',
                              // Style du texte
                              style: TextStyle(
                                // Taille
                                fontSize: 16,
                                // Poids
                                fontWeight: FontWeight.bold,
                                // Couleur
                                color: Colors.blue.shade800,
                              ),
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            // Texte
                            TextFormField(
                              // Contrôleur
                              controller: imageUrlController,
                              // Décoration
                              decoration: InputDecoration(
                                // Texte
                                labelText: 'URL de l\'image',
                                // Texte
                                hintText: 'https://example.com/image.jpg',
                                // Bordure
                                border: OutlineInputBorder(
                                  // Rayon de la bordure
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Couleur de fond
                                fillColor: Colors.white,
                                // Couleur de fond
                                filled: true,
                                // Icône
                                prefixIcon: const Icon(Icons.image),
                                // Texte
                                helperText: 'Laissez vide pour utiliser une image par défaut',
                                // Icône
                                suffixIcon: IconButton(
                                  // Icône
                                  icon: const Icon(Icons.preview),
                                  // Texte
                                  tooltip: 'Prévisualiser',
                                  onPressed: () {
                                    if (imageUrlController.text.isNotEmpty) {
                                      // Utiliser notre proxy pour éviter les problèmes de CORS
                                      final proxyUrl = imageUrlController.text.startsWith('http')
                                        ? 'http://172.16.199.254:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrlController.text)}'
                                        : 'http://172.16.199.254:3000/${imageUrlController.text}';
                                      // Afficher le dialogue
                                      showDialog(
                                        // Contexte
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          // Titre
                                          title: const Text('Prévisualisation de l\'image'),
                                          // Contenu
                                          content: Column(
                                            // Taille
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // SizedBox
                                              SizedBox(
                                                // Taille
                                                width: 300,
                                                // Taille
                                                height: 200,
                                                child: Image.network(
                                                  // URL
                                                  proxyUrl,
                                                  // Fit
                                                  fit: BoxFit.contain,
                                                  // Headers
                                                  headers: const {
                                                    // Accepte
                                                    'Accept': 'image/jpeg,image/png,image/gif,image/*',
                                                  },
                                                  // chargement de l'image 
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    // Si l'image est chargée
                                                    if (loadingProgress == null) return child;
                                                    // Retourner le centre
                                                    return Center(
                                                      // Contenu
                                                      child: CircularProgressIndicator(
                                                        // Valeur
                                                        value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                        // Couleur
                                                        color: Colors.blue.shade800,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    // Afficher l'erreur
                                                    print('Image preview error: $error');
                                                    // Retourner le contenu
                                                    return Column(
                                                      // Taille
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        // Icône
                                                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                                        // Espacement vertical
                                                        const SizedBox(height: 16),
                                                        // Texte
                                                        const Text('Erreur de chargement de l\'image'),
                                                        // Texte
                                                        Text(
                                                          // Texte
                                                          error.toString().substring(0, error.toString().length > 100 
                                                            // Si la chaîne est plus longue que 100 caractères
                                                            ? 100 
                                                            // Sinon, la chaîne entière
                                                            : error.toString().length),
                                                          // Style
                                                          style: const TextStyle(fontSize: 12),
                                                          // Alignement
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Actions
                                          actions: [
                                            // Texte
                                            TextButton(
                                              // Appuyer
                                              onPressed: () => Navigator.pop(context),
                                              // Texte
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              // Type de clavier
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Section des détails
                      Container(
                        // Padding
                        padding: const EdgeInsets.all(16),
                        // Décoration
                        decoration: BoxDecoration(
                          // Couleur de fond
                          color: Colors.grey.shade50,
                          // Rayon de la bordure  
                          borderRadius: BorderRadius.circular(12),
                          // Bordure
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          // Alignement du texte
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Texte
                            Text(
                              // Style
                              'Caractéristiques',
                              // Style
                              style: TextStyle(
                                // Taille
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            // Espacement vertical
                            const SizedBox(height: 16),
                            
                            // Layout à deux colonnes
                            Row(
                              // Alignement du texte
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Colonne gauche
                                Expanded(
                                  child: Column(
                                    // Contenu
                                    children: [
                                      // DropdownButtonFormField
                                      DropdownButtonFormField<String>(
                                        // Valeur
                                        value: selectedTransmission,
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Boîte de vitesse',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.settings),
                                        ),
                                        items: const [
                                          // Item
                                          DropdownMenuItem(value: 'Automatique', child: Text('Automatique')),
                                          DropdownMenuItem(value: 'Manuelle', child: Text('Manuelle')),
                                          DropdownMenuItem(value: 'PDK', child: Text('PDK')),
                                        ],
                                        onChanged: (value) {
                                          // Valeur
                                          selectedTransmission = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: doorsController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Nombre de portes',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.door_front_door),
                                        ),
                                        // Type de clavier
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Espacement horizontal
                                const SizedBox(width: 16),
                                
                                // Colonne droite
                                Expanded(
                                  child: Column(
                                    // Contenu
                                    children: [
                                      // DropdownButtonFormField
                                      DropdownButtonFormField<String>(
                                        // Valeur
                                        value: selectedEnergy,
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Énergie',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.local_gas_station),
                                        ),
                                        items: const [
                                          // Item
                                          DropdownMenuItem(value: 'Essence', child: Text('Essence')),
                                          DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                                          DropdownMenuItem(value: 'Électrique', child: Text('Électrique')),
                                          DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                                        ],
                                        onChanged: (value) {
                                          // Valeur
                                          selectedEnergy = value;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: seatsController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Nombre de places',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.event_seat),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        // Contrôleur
                                        controller: descriptionController,
                                        // Décoration
                                        decoration: InputDecoration(
                                          // Texte
                                          labelText: 'Description',
                                          // Bordure
                                          border: OutlineInputBorder(
                                            // Rayon de la bordure
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Couleur de fond
                                          fillColor: Colors.white,
                                          // Couleur de fond
                                          filled: true,
                                          // Icône
                                          prefixIcon: const Icon(Icons.description),
                                        ),
                                        // Nombre de lignes
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
                
                // Espacement vertical
                const SizedBox(height: 30),
                
                // Boutons d'action
                Row(
                  // Alignement du texte
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton
                    TextButton(
                      // Style
                      style: TextButton.styleFrom(
                        // Padding
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      // Appuyer
                      onPressed: () => Navigator.pop(context),
                      // Texte
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      // Icône
                      icon: const Icon(Icons.save),
                      // Texte
                      label: const Text('Mettre à jour'),
                      // Style
                      style: ElevatedButton.styleFrom(
                        // Couleur de fond
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          // Rayon de la bordure
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            // Mettre à jour les données du véhicule
                            final carData = {
                              // Nom de la marque
                              'NomMarque': selectedBrand,
                              // Modèle
                              'Modele': modelController.text,
                              // Année
                              'Annee': int.parse(yearController.text),
                              // Prix de location
                              'PrixLocation': double.parse(priceController.text),
                              // Statut
                              'IdStatut': selectedStatus,
                              // Boîte de vitesse
                              'BoiteVitesse': selectedTransmission,
                              // Énergie
                              'Energie': selectedEnergy,
                              // Type
                              'Type': selectedType,
                              // Couleur
                              'Couleur': colorController.text,
                              // Nombre de portes
                              'NbPorte': int.parse(doorsController.text),
                              // Nombre de places
                              'NbPlaces': int.parse(seatsController.text),
                              // Puissance
                              'Puissance': powerController.text.isNotEmpty ? int.parse(powerController.text) : 100,
                              // Description
                              'Description': descriptionController.text.isNotEmpty 
                                ? descriptionController.text
                                : '${selectedBrand} ${modelController.text}',
                              // URL de l'image
                              'Photo': imageUrlController.text,
                            };
                            
                            // Mettre à jour les données du véhicule
                            await _apiService.updateCar(car['IdVoiture'], carData);
                            
                            // Fermer le dialogue et actualiser les données
                            if (mounted) {
                              // Fermer le dialogue
                              Navigator.pop(context);
                              // Actualiser les données
                              _loadData();
                              // Afficher le message de succès
                              ScaffoldMessenger.of(context).showSnackBar(
                                // SnackBar
                                SnackBar(
                                  // Contenu
                                  content: Row(
                                    // Contenu
                                    children: [
                                      // Icône
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      // Espacement horizontal
                                      const SizedBox(width: 16),
                                      // Texte
                                      const Text('Véhicule mis à jour avec succès'),
                                    ],
                                  ),
                                  // Couleur de fond
                                  backgroundColor: Colors.green,
                                  // Comportement
                                  behavior: SnackBarBehavior.floating,
                                  // Forme
                                  shape: RoundedRectangleBorder(
                                    // Rayon de la bordure
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            } 
                          } catch (e) {
                            final errorMessage = 'Erreur: ${e.toString()}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
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
      ),
    );
  }
// Supprimer un véhicule
  void _deleteCar(Map<String, dynamic> car) {
    // Afficher le dialogue
    showDialog(
      // Contexte
      context: context,
      // Constructeur
      builder: (context) => Dialog(
        // Forme
        shape: RoundedRectangleBorder(
          // Rayon de la bordure
          borderRadius: BorderRadius.circular(16),
        ),
        // Élévation
        elevation: 0,
        // Couleur de fond
        backgroundColor: Colors.transparent,
        child: Container(
          // Padding
          padding: const EdgeInsets.all(24),
          // Décoration
          decoration: BoxDecoration(
            // Couleur de fond
            color: Colors.white,
            // Forme
            shape: BoxShape.rectangle,
            // Rayon de la bordure
            borderRadius: BorderRadius.circular(16),
            // Ombre
            boxShadow: [
              BoxShadow(
                // Couleur
                color: Colors.black26,
                // Rayon de l'ombre
                blurRadius: 10.0,
                // Décalage
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            // Taille
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // Padding
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Couleur de fond
                  color: Colors.red.shade50,
                  // Forme
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                // Texte
                'Supprimer le véhicule',
                // Style
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                // Alignement du texte
                textAlign: TextAlign.center,
                // Texte
                text: TextSpan(
                  // Style
                  style: TextStyle(
                    // Taille
                    fontSize: 16,
                    // Couleur
                    color: Colors.grey.shade800,
                  ),
                  children: [
                    // Texte
                    const TextSpan(text: 'Êtes-vous sûr de vouloir supprimer '),
                    // Texte
                    TextSpan(
                      // Texte
                      text: '${car['NomMarque']} ${car['Modele']}',
                      // Style
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Texte
                    const TextSpan(text: ' ? Cette action est irréversible.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                // Alignement du texte
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    // Style
                    style: OutlinedButton.styleFrom(
                      // Padding
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      // Forme
                      shape: RoundedRectangleBorder(
                        // Rayon de la bordure
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    // Icône
                    icon: const Icon(Icons.delete_outline, size: 18),
                    // Texte
                    label: const Text('Supprimer'),
                    // Style
                    style: ElevatedButton.styleFrom(
                      // Couleur de fond
                      backgroundColor: Colors.red,
                      // Couleur du texte
                      foregroundColor: Colors.white,
                      // Padding
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      // Forme
                      shape: RoundedRectangleBorder(
                        // Rayon de la bordure
                        borderRadius: BorderRadius  .circular(8),
                      ),
                    ),
                    // Appuyer
                    onPressed: () async {
                      try {
                        // Supprimer le véhicule
                        await _apiService.deleteCar(car['IdVoiture']);
                        // Fermer le dialogue et actualiser les données
                        if (mounted) {
                          // Fermer le dialogue
                          Navigator.pop(context);
                          // Actualiser les données
                          _loadData();
                          // Afficher le message de succès
                          ScaffoldMessenger.of(context).showSnackBar(
                            // SnackBar
                            const SnackBar(
                              content: Text('Véhicule supprimé avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        final errorMessage = 'Erreur: ${e.toString()}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
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

  // Afficher l'image du véhicule
  Widget _buildCarImage(Map<String, dynamic> car) {
    if (car['Photo'] == null || car['Photo'].toString().trim().isEmpty) {
      return _buildPlaceholderImage(car);
    }
    // Obtenir l'URL de l'image
    final imageUrl = _getImageUrl(car['Photo'].toString());
    print('Final image URL: $imageUrl');
    
    return ClipRRect(
      // Rayon de la bordure
      borderRadius: BorderRadius.circular(4),
      child: Container(
        // Taille
        width: 50,
        height: 50,
        // Décoration
        decoration: BoxDecoration(
          // Couleur de fond
          color: Colors.grey[200],
          // Rayon de la bordure
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          // Fit
          fit: StackFit.expand,
          children: [
            // Placeholder
            Center(
              child: _buildPlaceholderImage(car),
            ),
            // Image
            Image.network(
              imageUrl,
              // Fit
              fit: BoxFit.cover,
              headers: const {
                'Accept': 'image/jpeg,image/png,image/gif,image/*',
              },
              cacheWidth: 100,
              // Erreur
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: ${car['Photo']} - $error');
                return _buildPlaceholderImage(car);
              },
              // Chargement
              loadingBuilder: (context, child, loadingProgress) {
                // Si aucune erreur
                if (loadingProgress == null) return child;
                // Centrer le chargement
                return Center(
                  child: CircularProgressIndicator(
                    // Valeur
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    // Largeur
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
    // Obtenir la marque et le modèle à afficher
    final make = car['NomMarque'] as String? ?? '';
    final model = car['Modele'] as String? ?? '';
    final shortName = make.isNotEmpty ? make[0] + (model.isNotEmpty ? model[0] : '') : '?';
    
    return Container(
      // Taille
      width: 50,
      height: 50,
      // Décoration
      decoration: BoxDecoration(
        // Gradient
        gradient: LinearGradient(
          // Début
          begin: Alignment.topLeft,
          // Fin
          end: Alignment.bottomRight,
          // Couleurs
          colors: [Colors.blue.shade300, Colors.blue.shade600],
        ),
        // Rayon de la bordure
        borderRadius: BorderRadius.circular(4),
        // Ombre
        boxShadow: [
          BoxShadow(
            // Couleur
            color: Colors.black.withOpacity(0.1),
            // Rayon de l'ombre
            blurRadius: 2,
            // Décalage
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Column(
          // Alignement du texte
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // Texte
              shortName,
              // Style
              style: const TextStyle(
                // Taille
                fontSize: 18,
                // Couleur
                color: Colors.white,
              ),
            ),
            if (make.isNotEmpty || model.isNotEmpty)
              Text(
                // Texte
                make.isNotEmpty ? make : model,
                // Style
                style: const TextStyle(
                  // Taille
                  fontSize: 8,
                  // Couleur
                  color: Colors.white,
                  // Ombres
                  shadows: [
                    Shadow(
                      // Rayon de l'ombre
                      blurRadius: 2,
                      // Couleur
                      color: Colors.black26,
                      // Décalage
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                // Dépassement
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
// Obtenir l'URL de l'image
  String _getImageUrl(String imageUrl) {
    // Log l'URL originale pour le débogage
    print('Traitement de l\'URL de l\'image: $imageUrl');
    
    // Si l'URL est vide ou null, retourner une image par défaut
    if (imageUrl == null || imageUrl.isEmpty) {
      return 'http://172.16.199.254:3000/api/assets/images/default-car.jpg';
    }
    
    // Gérer les URLs de motor1.com via notre proxy pour résoudre les problèmes de CORS
    if (imageUrl.contains('cdn.motor1.com')) {
      print('Utilisation du proxy pour l\'URL de motor1.com: $imageUrl');
      return 'http://172.16.199.254:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
    }
    // Gérer les autres URLs externes
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('Utilisation du proxy pour l\'URL externe: $imageUrl');
      return 'http://172.16.199.254:3000/api/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
    } 
    // Gérer les chemins locaux
    else if (imageUrl.startsWith('assets/')) {
      print('Utilisation du chemin local: $imageUrl');
      return 'http://172.16.199.254:3000/$imageUrl';
    } 
    // Cas par défaut
    else {
      print('Utilisation du chemin par défaut: $imageUrl');
      return 'http://172.16.199.254:3000/$imageUrl';
    }
  }
} 
