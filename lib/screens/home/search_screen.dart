import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/offer_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedVehicleType;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _search() {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    offerProvider.searchOffers(
      fromLocation: _fromController.text.trim(),
      toLocation: _toController.text.trim(),
      date: _selectedDate,
      vehicleType: _selectedVehicleType,
    );
  }

  void _clearFilters() {
    _fromController.clear();
    _toController.clear();
    setState(() {
      _selectedDate = null;
      _selectedVehicleType = null;
    });
    Provider.of<OfferProvider>(context, listen: false).clearFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Rides'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Filters
          Container(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            color: Colors.white,
            child: Column(
              children: [
                // From Location
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'From',
                    hintText: 'Enter departure location',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        _fromController.text = value;
                      },
                      itemBuilder: (context) {
                        return AppConstants.popularLocations.map((location) {
                          return PopupMenuItem(
                            value: location,
                            child: Text(location),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // To Location
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'To',
                    hintText: 'Enter destination',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        _toController.text = value;
                      },
                      itemBuilder: (context) {
                        return AppConstants.popularLocations.map((location) {
                          return PopupMenuItem(
                            value: location,
                            child: Text(location),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Date & Vehicle Type Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? Helpers.formatDate(_selectedDate!)
                                : 'Any Date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle',
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        hint: const Text('Any'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
                          ),
                          ...AppConstants.vehicleTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: Consumer<OfferProvider>(
              builder: (context, offerProvider, child) {
                if (offerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (offerProvider.offers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No rides found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search filters',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(UIConstants.defaultPadding),
                  itemCount: offerProvider.offers.length,
                  itemBuilder: (context, index) {
                    final offer = offerProvider.offers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OfferCard(
                        offer: offer,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/offer-detail',
                            arguments: offer,
                          );
                        },
                      ),
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
}
