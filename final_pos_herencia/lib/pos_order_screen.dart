import 'package:flutter/material.dart';
import 'history_screen.dart' as history;

import 'helpers/database_helper.dart';
import 'models/menu_item_model.dart';
import 'models/sale_model.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;

  const Category({required this.id, required this.name, required this.icon});
}

class OrderItem {
  final MenuItemModel menuItem;
  int quantity;
  String? selectedVariety;
  String? notes;

  OrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedVariety,
    this.notes,
  });

  double get totalPrice => menuItem.price * quantity;
}

//POS Order Screen Widget
class PosOrderScreen extends StatefulWidget {
  const PosOrderScreen({super.key});

  @override
  State<PosOrderScreen> createState() => _PosOrderScreenState();
}

class _PosOrderScreenState extends State<PosOrderScreen> with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();

  //Notification Animation Controller
  late AnimationController _notificationAnimationController;
  late Animation<Offset> _notificationSlideAnimation;
  late Animation<double> _notificationFadeAnimation;
  bool _showNotification = false;

  //State Variables
  String _selectedCategoryId = 'Main';
  final List<OrderItem> _currentOrder = [];
  String _orderType = "Dine In";
  String _currentSortOrder = 'none';
  MenuItemModel? _selectedMenuItemForDetail;
  bool _showItemDetailSidebar = false;
  late AnimationController _itemDetailAnimationController;
  late Animation<Offset> _itemDetailOffsetAnimation;

  //Left Sidebar State
  bool _showLeftSidebar = false;
  late AnimationController _leftSidebarAnimationController;
  late Animation<Offset> _leftSidebarOffsetAnimation;

  //Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  //Categories
  final List<Category> _categories = [
    const Category(id: 'Main', name: 'Main Dish', icon: Icons.local_pizza),
    const Category(id: 'Soup', name: 'Side Dish', icon: Icons.lunch_dining),
    const Category(id: 'Dessert', name: 'Dessert', icon: Icons.rice_bowl),
    const Category(id: 'Snacks', name: 'Snacks', icon: Icons.fastfood),
    const Category(id: 'Drinks', name: 'Drinks', icon: Icons.local_bar),
  ];

  List<MenuItemModel> _dbMenuItems = [];
  bool _isLoadingMenuItems = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();

    //Animation Controller
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _notificationSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _notificationAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _notificationFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationAnimationController,
      curve: Curves.easeInOut,
    ));

    _itemDetailAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _itemDetailOffsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _itemDetailAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _leftSidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _leftSidebarOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _leftSidebarAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoadingMenuItems = true;
    });
    print("Attempting to load menu items from local DB...");
    List<MenuItemModel> items = await _dbHelper.getAllMenuItems();
    
    if (items.isEmpty) {
      print("Local DB is empty. Fetching from Firestore...");
      await _syncService.fetchMenuFromFirebasePaginated();
      items = await _dbHelper.getAllMenuItems();
    }
    print("${items.length} items loaded.");
    
    setState(() {
      _dbMenuItems = items;
      _isLoadingMenuItems = false;
    });
  }

  @override
  void dispose() {
    _itemDetailAnimationController.dispose();
    _leftSidebarAnimationController.dispose();
    _notificationAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSuccessNotification() {
    setState(() => _showNotification = true);
    _notificationAnimationController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _notificationAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() => _showNotification = false);
          }
        });
      }
    });
  }

  List<MenuItemModel> get _filteredMenuItems {
    List<MenuItemModel> itemsToShow;

    // Debug Print
    print("Filtering menu items - Total items in DB: ${_dbMenuItems.length}");
    print("Current category: $_selectedCategoryId");

    if (_searchQuery.isNotEmpty) {
      itemsToShow = _dbMenuItems.where((item) { 
        final nameLower = item.name.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        final descriptionLower = item.description?.toLowerCase() ?? '';
        return nameLower.contains(queryLower) || descriptionLower.contains(queryLower);
      }).toList();
    } else {
      itemsToShow = _dbMenuItems.where((item) {
        print("Item ${item.name} has categoryId: ${item.categoryId}");
        return item.categoryId.toLowerCase() == _selectedCategoryId.toLowerCase();
      }).toList(); 
    }

    print("Filtered items count: ${itemsToShow.length}");

    if (_currentSortOrder == 'az') {
      itemsToShow.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_currentSortOrder == 'za') {
      itemsToShow.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return itemsToShow;
  }

  void _toggleItemDetailSidebar(MenuItemModel? item) {
    setState(() {
      if (item != null) {
        _selectedMenuItemForDetail = item;
        _showItemDetailSidebar = true;
        _itemDetailAnimationController.forward();
      } else {
        _itemDetailAnimationController.reverse().then((value) {
          if (mounted) {
             setState(() {
                _showItemDetailSidebar = false;
                _selectedMenuItemForDetail = null;
            });
          }
        });
      }
    });
  }

  //Toggle Left Sidebar
  void _toggleLeftSidebar() {
    setState(() {
      if (_showLeftSidebar) {
        _leftSidebarAnimationController.reverse().then((value) {
          if (mounted) {
            setState(() {
              _showLeftSidebar = false;
            });
          }
        });
      } else {
        _showLeftSidebar = true;
        _leftSidebarAnimationController.forward();
      }
    });
  }

  //Build Method
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 1200;
    final double sidebarWidth = isLargeScreen ? 400 : 350;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 26.0),
                _buildAppBar(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildMenuDisplayArea(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 28.0, 0.0),
                        child: Container(
                          width: sidebarWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(128, 128, 128, 0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: _buildOrderSummaryArea(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //Success Notification
            if (_showNotification)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _notificationSlideAnimation,
                  child: FadeTransition(
                    opacity: _notificationFadeAnimation,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Order Successfully Placed!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Dimming overlay (conditionally visible)
            if (_showItemDetailSidebar)
              AnimatedOpacity(
                opacity: 1.0,
                duration: _itemDetailAnimationController.duration ?? const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () => _toggleItemDetailSidebar(null),
                  child: Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                  ),
                ),
              ),
            if (_showLeftSidebar)
              AnimatedOpacity(
                opacity: 1.0,
                duration: _leftSidebarAnimationController.duration ?? const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _toggleLeftSidebar,
                  child: Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                  ),
                ),
              ),

            //Item Detail Sidebar
            if (_showItemDetailSidebar && _selectedMenuItemForDetail != null)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _itemDetailOffsetAnimation,
                  child: Material(
                    elevation: 0, 
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25.0),
                        bottomLeft: Radius.circular(25.0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: sidebarWidth + 50, 
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          bottomLeft: Radius.circular(30.0),
                        ),
                      ),
                      child: _buildItemDetailSidebar(_selectedMenuItemForDetail!),
                    ),
                  ),
                ),
              ),

            //Left Sidebar
            if (_showLeftSidebar)
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _leftSidebarOffsetAnimation,
                  child: Material(
                    elevation: 16,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(25.0),
                        bottomRight: Radius.circular(25.0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: sidebarWidth,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30.0),
                          bottomRight: Radius.circular(30.0),
                        ),
                      ),
                      child: _buildLeftSidebarContent(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //Top Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFBFBFA), 
      elevation: 0, 
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: IconButton(
          iconSize: 35.0,
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () {
            _toggleLeftSidebar();
          },
        ),
      ),
      title: Padding( 
        padding: const EdgeInsets.only(left: 25.0),
        child: Row(
          children: [
            SizedBox(
              height: 56,
              width: MediaQuery.of(context).size.width * 0.45,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search Category or Menu",
                  hintStyle: const TextStyle(fontWeight: FontWeight.w600),
                  suffixIcon: const Icon(Icons.search, size: 28),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: const [],
    );
  }

  //Main Content Area
  Widget _buildMenuDisplayArea() {
    return Container(
      color: const Color(0xFFFBFBFA), 
      child: Padding(
        padding: const EdgeInsets.all(28.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryFilters(),
            const SizedBox(height: 20),
            _buildMenuItemListHeader(),
            const SizedBox(height: 15),
            Expanded(child: _buildMenuItemGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          bool isSelected = category.id == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ChoiceChip(
              label: Text(category.name),
              avatar: Icon(
                category.icon,
                color: isSelected ? Colors.white : Colors.orange.shade700,
                size: 24,
              ),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                }
              },
              backgroundColor: const Color(0xFFEDECED),
              selectedColor: Colors.orange.shade600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87, 
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.orange.shade600 : Colors.grey.shade300)
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemListHeader() {
    String categoryName = _categories.firstWhere((cat) => cat.id == _selectedCategoryId, orElse: () => const Category(id: '', name: 'Items', icon: Icons.list)).name;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          " $categoryName",
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        PopupMenuButton<String>(
          onSelected: (String value) {
            setState(() {
              _currentSortOrder = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Sorted by: ${_currentSortOrder == 'az' ? 'A-Z' : 'Z-A'}")),
            );
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'az',
              child: Text('Sort A-Z'),
            ),
            const PopupMenuItem<String>(
              value: 'za',
              child: Text('Sort Z-A'),
            ),
          ],
          tooltip: "Sort items",
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, color: Colors.black54, size: 26),
                SizedBox(width: 8),
                Text("Sort", style: TextStyle(color: Colors.black54, fontSize: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemGrid() {
    if (_filteredMenuItems.isEmpty) {
      return const Center(child: Text("No items available in this category."));
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredMenuItems.length,
      itemBuilder: (context, index) {
        final item = _filteredMenuItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _toggleItemDetailSidebar(item);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 15.0),
                child: SizedBox(
                  width: 225,
                  height: 225,
                  child: item.imageUrl?.isNotEmpty ?? false
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
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
                            return Icon(Icons.broken_image, size: 40, color: Colors.grey.shade700);
                          },
                        )
                      : Icon(Icons.fastfood, size: 40, color: Colors.grey.shade700),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center, 
                    ),
                    if (item.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        item.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    Text(
                      "₱${item.price.toStringAsFixed(2)}", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade800)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Item Detail Sidebar Widget
  Widget _buildItemDetailSidebar(MenuItemModel item) {
    String? currentSelectedVariety = item.varieties.isNotEmpty ? item.varieties.first : null;
    double currentPrice = this.getPriceForVariety(item, currentSelectedVariety);
    TextEditingController notesController = TextEditingController();
    int quantity = 1;

    return StatefulBuilder(builder: (BuildContext context, StateSetter setSidebarState) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28.0, 20.0, 20.0, 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: item.imageUrl?.isNotEmpty ?? false
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
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
                                return Icon(Icons.broken_image, size: 100, color: Colors.grey.shade400);
                              },
                            )
                          : Icon(Icons.image_outlined, size: 100, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      "₱${currentPrice.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    
                    if (item.varieties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10.0,
                              runSpacing: 10.0,
                              alignment: WrapAlignment.center,
                              children: item.varieties.map((variety) {
                                bool isSelected = currentSelectedVariety == variety;
                                return ChoiceChip(
                                  label: Text(
                                    variety, 
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87, 
                                      fontSize: 16
                                    )
                                  ),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setSidebarState(() {
                                        currentSelectedVariety = variety;
                                        currentPrice = this.getPriceForVariety(item, variety);
                                      });
                                    }
                                  },
                                  selectedColor: Colors.orange.shade600,
                                  backgroundColor: Colors.grey.shade100,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Quantity:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 30),
                                onPressed: quantity > 1 ? () => setSidebarState(() => quantity--) : null,
                                color: Colors.orange.shade700,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quantity.toString(), 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 30),
                                onPressed: () => setSidebarState(() => quantity++),
                                color: Colors.orange.shade700,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: "Notes (e.g., Extra cheese)",
                          hintText: "Any special requests?",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: () {
                  _addItemToOrder(item, quantity, currentSelectedVariety, notesController.text);
                  _toggleItemDetailSidebar(null);
                },
                child: const Text(
                  "Add to Order", 
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _addItemToOrder(MenuItemModel item, int quantity, String? variety, String notes) {
    final MenuItemModel itemForOrder = MenuItemModel(
        id: item.id,
        name: item.name,
        categoryId: item.categoryId,
        price: this.getPriceForVariety(item, variety),
        imageUrl: item.imageUrl,
        stock: item.stock,
        varieties: item.varieties,
        description: item.description,
        lastUpdated: item.lastUpdated,
        firebaseDocId: item.firebaseDocId
    );

    setState(() {
      int existingIndex = _currentOrder.indexWhere(
          (orderItem) => orderItem.menuItem.id == itemForOrder.id && orderItem.selectedVariety == variety);

      if (existingIndex != -1) {
        _currentOrder[existingIndex].quantity += quantity;
        if (notes.isNotEmpty && _currentOrder[existingIndex].notes != null) {
             _currentOrder[existingIndex].notes = "${_currentOrder[existingIndex].notes}, $notes";
        } else if (notes.isNotEmpty) {
            _currentOrder[existingIndex].notes = notes;
        }
      } else {
        _currentOrder.add(OrderItem(
          menuItem: itemForOrder,
          quantity: quantity,
          selectedVariety: variety,
          notes: notes.isNotEmpty ? notes : null,
        ));
      }
    });
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${item.name} added to order."), duration: const Duration(seconds: 1), backgroundColor: Colors.green,),
    );
  }

  double getPriceForVariety(MenuItemModel item, String? variety) {
      if (variety == "Large") return item.price + 2.00;
      if (variety == "Extra Large") return item.price + 3.50;
      if (variety == "Stuffed Crust") return item.price + 1.50;
      return item.price;
  }

  //Current Order Summary
  Widget _buildOrderSummaryArea() {
    double itemsSubtotal = _currentOrder.fold(0, (sum, item) => sum + item.totalPrice);
    double taxRate = 0.10;
    double taxAmount = itemsSubtotal * taxRate;
    double finalTotalAmount = double.parse((itemsSubtotal + taxAmount).toStringAsFixed(2));

    return Padding(
      padding: const EdgeInsets.fromLTRB(26.0, 36.0, 26.0, 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Order Details", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              Text("#907653", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _orderType = "Dine In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orderType == "Dine In" ? Colors.orange.shade600 : Colors.white,
                    foregroundColor: _orderType == "Dine In" ? Colors.white : Colors.black54,
                    side: _orderType == "Dine In" ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)))
                  ),
                  child: const Text("Dine In", style: TextStyle(fontSize: 16)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _orderType = "Take Out"),
                   style: ElevatedButton.styleFrom(
                    backgroundColor: _orderType == "Take Out" ? Colors.orange.shade600 : Colors.white,
                    foregroundColor: _orderType == "Take Out" ? Colors.white : Colors.black54,
                    side: _orderType == "Take Out" ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)))
                  ),
                  child: const Text("Take Out", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: _currentOrder.isEmpty
                ? const Center(child: Text("No items added to order yet.", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: _currentOrder.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final orderItem = _currentOrder[index];
                      return _buildOrderItemTile(orderItem, index);
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                _buildTotalRow("Items (${_currentOrder.length})", "₱${itemsSubtotal.toStringAsFixed(2)}"),
                _buildTotalRow("Tax (${(taxRate * 100).toStringAsFixed(0)}%)", "₱${taxAmount.toStringAsFixed(2)}"),
                const SizedBox(height: 5),
                _buildTotalRow("Total", "₱${finalTotalAmount.toStringAsFixed(2)}", isTotal: true),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentOrder.isEmpty ? null : () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to proceed with this order?'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                      actionsAlignment: MainAxisAlignment.spaceEvenly,
                      actions: <Widget>[
                        TextButton(
                          child: const Text('No', style: TextStyle(fontSize: 16, color: Colors.redAccent)),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
                          ),
                          child: const Text('Yes, Proceed', style: TextStyle(fontSize: 16, color: Colors.white)),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();

                            if (_currentOrder.isNotEmpty) {
                              final String? cashierId = _authService.currentUser?.uid;
                              if (cashierId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Error: Cashier not logged in. Cannot place order."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              double currentItemsSubtotal = _currentOrder.fold(0, (sum, item) => sum + item.totalPrice);
                              double currentTaxRate = 0.10;
                              double currentTaxAmount = currentItemsSubtotal * currentTaxRate;
                              double finalTotalAmount = double.parse((currentItemsSubtotal + currentTaxAmount).toStringAsFixed(2));

                              List<SaleOrderItem> saleOrderItems = _currentOrder.map((orderItem) {
                                return SaleOrderItem(
                                  menuItemId: orderItem.menuItem.id,
                                  name: orderItem.menuItem.name,
                                  priceAtSale: orderItem.menuItem.price,
                                  quantity: orderItem.quantity,
                                  selectedVariety: orderItem.selectedVariety,
                                  notes: orderItem.notes,
                                );
                              }).toList();

                              //Create SaleModel
                              SaleModel newSale = SaleModel(
                                cashierId: cashierId,
                                items: saleOrderItems,
                                totalAmount: finalTotalAmount,
                                saleTimestamp: DateTime.now().millisecondsSinceEpoch,
                                orderType: _orderType,
                                isSynced: false,
                              );

                              try {
                                //Save to Local DB (sqflite)
                                SaleModel createdSale = await _dbHelper.insertSale(newSale);
                                
                                if (createdSale.id != null) {
                                  //Update Stock Levels
                                  for (var orderItemInSale in _currentOrder) {
                                    MenuItemModel? itemToUpdate = await _dbHelper.getMenuItemById(orderItemInSale.menuItem.id);
                                    if (itemToUpdate != null) {
                                      int newStock = itemToUpdate.stock - orderItemInSale.quantity;
                                      await _dbHelper.updateMenuItem(itemToUpdate.copyWith(
                                        stock: newStock < 0 ? 0 : newStock,
                                        lastUpdated: DateTime.now().millisecondsSinceEpoch
                                      ));
                                    }
                                  }
                                  // Reload menu items
                                  await _loadMenuItems();

                                  //Push to Firebase
                                  _syncService.pushSalesToFirebase().catchError((e) {
                                    print("Error pushing sales to Firebase immediately after order: $e");
                                  });

                                  // Keep existing history
                                  List<history.OrderItem> transactionHistoryOrderItems = _currentOrder.map((posScreenOrderItem) {
                                    history.MenuItem historyMenuItem = history.MenuItem(
                                      id: posScreenOrderItem.menuItem.id,
                                      name: posScreenOrderItem.menuItem.name,
                                      price: posScreenOrderItem.menuItem.price,
                                      imageUrl: posScreenOrderItem.menuItem.imageUrl ?? '',
                                    );
                                    return history.OrderItem(
                                      menuItem: historyMenuItem,
                                      quantity: posScreenOrderItem.quantity,
                                      selectedVariety: posScreenOrderItem.selectedVariety,
                                      notes: posScreenOrderItem.notes,
                                    );
                                  }).toList();

                                  String transactionIdForHistory = createdSale.id.toString();

                                  history.Transaction newTransaction = history.Transaction(
                                    id: transactionIdForHistory, 
                                    date: DateTime.fromMillisecondsSinceEpoch(createdSale.saleTimestamp),
                                    items: transactionHistoryOrderItems,
                                    totalAmount: createdSale.totalAmount,
                                    orderType: createdSale.orderType,
                                  );
                                  history.HistoryScreen.addTransactionEntry(newTransaction);

                                  setState(() {
                                    _currentOrder.clear();
                                    _showNotification = true;
                                  });

                                  // Start the notification animation
                                  _notificationAnimationController.forward().then((value) {
                                    Future.delayed(const Duration(seconds: 3), () {
                                      _notificationAnimationController.reverse();
                                    });
                                  });

                                  _showSuccessNotification();

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error: Could not save order locally (no ID returned)."),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } catch (e, s) {
                                print("Error processing order: $e\\n$s");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("An error occurred: $e"),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')
              ),
              child: const Text("Proceed To Order"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderItemTile(OrderItem orderItem, int index) {
    bool hasVariety = orderItem.selectedVariety != null;
    bool hasNotes = orderItem.notes?.isNotEmpty ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          width: 65,
          height: 65,
          color: Colors.orange.shade50,
          padding: const EdgeInsets.all(4.0),
          child: orderItem.menuItem.imageUrl?.isNotEmpty ?? false
              ? Image.asset(
                  orderItem.menuItem.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image, size: 35, color: Colors.grey.shade700);
                  },
                )
              : Icon(Icons.fastfood, size: 35, color: Colors.grey.shade700),
        ),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  orderItem.menuItem.name, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                ),
                if (hasVariety)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text("Variety: ${orderItem.selectedVariety!}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                if (hasNotes)
                  Padding(
                    padding: EdgeInsets.only(top: (hasVariety) ? 2.0 : 2.0),
                    child: Text(
                      "Note: ${orderItem.notes ?? ''}", 
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: (hasVariety || hasNotes) ? 4.0 : 2.0),
                  child: Text(
                    "\$${orderItem.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 24),
                    color: Colors.red.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        if (orderItem.quantity > 1) {
                          orderItem.quantity--;
                        } else {
                          _currentOrder.removeAt(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${orderItem.menuItem.name} removed from order."), duration: const Duration(seconds: 1), backgroundColor: Colors.redAccent,),
                          );
                        }
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(orderItem.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    color: Colors.green.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        orderItem.quantity++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.edit_note_outlined, size: 22),
                color: Colors.blue.shade600,
                tooltip: "Edit Item",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _editOrderItemDialog(orderItem, index);
                },
              ),
            ],
          )
        ],
      ),
      subtitle: null,
      trailing: null, 
    );
  }

  void _editOrderItemDialog(OrderItem orderItemToEdit, int itemIndexInOrder) {
    final originalMenuItemDef = _dbMenuItems.firstWhere((item) => item.id == orderItemToEdit.menuItem.id);
    String? selectedVariety = orderItemToEdit.selectedVariety ?? (originalMenuItemDef.varieties.isNotEmpty ? originalMenuItemDef.varieties.first : null);
    TextEditingController notesController = TextEditingController(text: orderItemToEdit.notes ?? '');
    int quantity = orderItemToEdit.quantity;
    double currentPriceInDialog = getPriceForVariety(originalMenuItemDef, selectedVariety);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogStateInEdit) {
            return AlertDialog(
              title: Text("Edit: ${orderItemToEdit.menuItem.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              contentPadding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (originalMenuItemDef.varieties.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Select Variety: (current price: \$${currentPriceInDialog.toStringAsFixed(2)})", 
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: originalMenuItemDef.varieties.map((variety) {
                              bool isSelected = selectedVariety == variety;
                              return ChoiceChip(
                                label: Text(variety),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    setDialogStateInEdit(() {
                                      selectedVariety = variety;
                                      currentPriceInDialog = getPriceForVariety(originalMenuItemDef, selectedVariety);
                                    });
                                  }
                                },
                                selectedColor: Colors.orange.shade600,
                                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                                backgroundColor: Colors.grey.shade100,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Quantity:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 28),
                              onPressed: quantity > 1 ? () => setDialogStateInEdit(() => quantity--) : null,
                              color: Colors.orange.shade700,
                            ),
                            Text(quantity.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 28),
                              onPressed: () => setDialogStateInEdit(() => quantity++),
                              color: Colors.orange.shade700,
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: "Notes",
                        hintText: "Update special requests?",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceAround,
              actionsPadding: const EdgeInsets.only(bottom: 15, top:10, left: 15, right: 15),
              actions: <Widget>[
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                     side: const BorderSide(color: Colors.redAccent),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  ),
                  onPressed: () {
                    setState(() {
                      _currentOrder.removeAt(itemIndexInOrder);
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${orderItemToEdit.menuItem.name} removed."), backgroundColor: Colors.redAccent, duration: const Duration(seconds:1)),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Update Order"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  ),
                  onPressed: () {
                    final double finalPriceForVariety = getPriceForVariety(originalMenuItemDef, selectedVariety);

                    final MenuItemModel updatedMenuItem = MenuItemModel(
                      id: originalMenuItemDef.id,
                      name: originalMenuItemDef.name,
                      categoryId: originalMenuItemDef.categoryId,
                      price: finalPriceForVariety,
                      imageUrl: originalMenuItemDef.imageUrl,
                      stock: originalMenuItemDef.stock, 
                      varieties: originalMenuItemDef.varieties,
                      description: originalMenuItemDef.description,
                      lastUpdated: originalMenuItemDef.lastUpdated,
                      firebaseDocId: originalMenuItemDef.firebaseDocId
                    );

                    final OrderItem updatedOrderItem = OrderItem(
                      menuItem: updatedMenuItem,
                      quantity: quantity,
                      selectedVariety: selectedVariety,
                      notes: notesController.text.isNotEmpty ? notesController.text : null,
                    );

                    setState(() {
                      _currentOrder[itemIndexInOrder] = updatedOrderItem;
                    });
                    Navigator.of(context).pop();
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${orderItemToEdit.menuItem.name} updated."), backgroundColor: Colors.green, duration: const Duration(seconds:1)),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

   Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 19 : 17, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
          Text(amount, style: TextStyle(fontSize: isTotal ? 19 : 17, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
        ],
      ),
    );
  }

  //Left Sidebar Content
  Widget _buildLeftSidebarContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left:16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: Colors.black54, size: 35), 
                      const SizedBox(width: 15), 
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 33, color: Colors.black, fontFamily: 'Poppins'),
                          children: <TextSpan>[
                            const TextSpan(text: 'Herencia'),
                            TextSpan(text: 'POS', style: TextStyle(color: Colors.orange.shade700, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text(
                'Dashboard',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                _toggleLeftSidebar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dashboard tapped (not implemented)")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text(
                'History',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                _toggleLeftSidebar();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const history.HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text(
                'Settings',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                _toggleLeftSidebar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings tapped (not implemented)")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(
                'About',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                _toggleLeftSidebar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("About tapped (not implemented)")),
                );
              },
            ),
            const Spacer(),

            // User Profile and Logout Box
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: _buildUserInfoBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoBox() {
    String cashierName = "Cashier";
    String cashierTitle = "Cashier";
    String avatarUrl = "assets/images/avatar_placeholder.png";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
         boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage(avatarUrl),
            onBackgroundImageError: (exception, stackTrace) {
            },
            backgroundColor: Colors.orange.shade100,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.orange) : null,
          ),
          const SizedBox(height: 12),
          Text(
            cashierName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            cashierTitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () async {
              print("Log out tapped from UserInfoBox");
              await _authService.signOut();
              if (_showLeftSidebar && mounted) {
                 _toggleLeftSidebar();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Log out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
