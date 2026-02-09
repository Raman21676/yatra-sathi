import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../offers/post_offer_screen.dart';
import 'offers_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load offers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfferProvider>(context, listen: false).loadOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(UIConstants.primaryColor),
                    Color(UIConstants.secondaryColor),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(UIConstants.largeRadius),
                  bottomRight: Radius.circular(UIConstants.largeRadius),
                ),
              ),
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
                              '${Helpers.getGreeting()},',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.name ?? 'Guest',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (user?.photo != null && user!.photo.isNotEmpty)
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(user.photo),
                        )
                      else
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          UIConstants.defaultRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            'Search rides...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<OfferProvider>(context, listen: false)
                      .loadOffers(refresh: true);
                },
                child: const OffersListScreen(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PostOfferScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Ride'),
      ),
    );
  }
}
