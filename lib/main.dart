import 'package:flutter/material.dart';

class DockItem {
  final IconData icon;
  final String label;
  final Color color;

  const DockItem({
    required this.icon, 
    required this.label,
    required this.color,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DockExample(),
    );
  }
}

class DockExample extends StatelessWidget {
  const DockExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5364), Color(0xFF203A43), Color(0xFF0F2027)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: MacOSDock(
                items: const [
                  DockItem(
                    icon: Icons.home_rounded,
                    label: 'Finder',
                    color: Colors.blue,
                  ),
                  DockItem(
                    icon: Icons.terminal_rounded,
                    label: 'Terminal',
                    color: Colors.grey,
                  ),
                  DockItem(
                    icon: Icons.web_rounded,
                    label: 'Safari',
                    color: Colors.lightBlue,
                  ),
                  DockItem(
                    icon: Icons.mail_rounded,
                    label: 'Mail',
                    color: Colors.blueGrey,
                  ),
                  DockItem(
                    icon: Icons.message_rounded,
                    label: 'Messages',
                    color: Colors.green,
                  ),
                  DockItem(
                    icon: Icons.music_note_rounded,
                    label: 'Music',
                    color: Colors.red,
                  ),
                  DockItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Photos',
                    color: Colors.purple,
                  ),
                  DockItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: Colors.grey,
                  ),
                  DockItem(
                    icon: Icons.apps_rounded,
                    label: 'App Store',
                    color: Colors.blue,
                  ),
                  DockItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Calendar',
                    color: Colors.orange,
                  ),
                  DockItem(
                    icon: Icons.contacts_rounded,
                    label: 'Contacts',
                    color: Colors.amber,
                  ),
                  DockItem(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    color: Colors.yellow,
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

class MacOSDock extends StatefulWidget {
  final List<DockItem> items;

  const MacOSDock({
    super.key,
    required this.items,
  });

  @override
  State<MacOSDock> createState() => _MacOSDockState();
}

class _MacOSDockState extends State<MacOSDock> with SingleTickerProviderStateMixin {
  static const double baseWidth = 45.0;
  static const double baseHeight = 45.0;
  static const double itemSpacing = 20.0;
  static const double maxScale = 1.3;
  static const double dragScale = 1.3;
  static const double adjacentScale = 1.1;
  static const double maxVerticalOffset = 20.0;
  static const double liftedSpacing = 6.0;
  static const double liftThreshold = -10.0;  // Threshold for considering item as lifted
  static const double compressedSpacing = 2.0;  // Even smaller spacing when compressed
  static const double liftedScale = 1.5;  // Add this constant for lifted item scale
  
  late List<DockItem> _items;
  double? _mouseX;
  double? _mouseY;
  int? _dragIndex;
  double? _dragStartX;
  double? _dragStartY;
  DockItem? _draggedItem;  // Store the lifted item
  bool _isLifted = false;  // Track if item is lifted
  late AnimationController _insertController;
  double _insertProgress = 0.0;
  int? _insertIndex;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    _insertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
      setState(() {
        _insertProgress = _insertController.value;
      });
    });
  }

  @override
  void dispose() {
    _insertController.dispose();
    super.dispose();
  }

  double _getItemScale(int index) {
    if (_mouseX == null) return 1.0;
    
    if (_dragIndex != null) {
      if (index == _dragIndex) return dragScale;
      if ((index == _dragIndex! - 1) || (index == _dragIndex! + 1)) {
        return adjacentScale;
      }
      return 1.0;
    }

    final itemCenter = _getItemCenter(index);
    final distance = (_mouseX! - itemCenter).abs();
    const influence = 100.0;

    if (distance >= influence) return 1.0;
    
    final t = (influence - distance) / influence;
    return 1.0 + (maxScale - 1.0) * (1 - (1 - t) * (1 - t));
  }

  double _getItemCenter(int index) {
    // Always return stable position for non-dragged items
    return index * (baseWidth + itemSpacing) + baseWidth / 2;
  }

  double _getItemOffset(int index) {
    if (_dragIndex == null || _dragStartX == null || _mouseX == null) return 0;

    // Calculate insertion animation offset
    if (_insertIndex != null) {
      if (index >= _insertIndex!) {
        // Items after insert point move right
        return itemSpacing * _insertProgress;
      } else if (index < _insertIndex!) {
        // Items before insert point move left
        return -itemSpacing * _insertProgress;
      }
    }

    // Normal drag offset
    if (index == _dragIndex) {
      return _mouseX! - _dragStartX!;
    }

    return 0;
  }

  double _getVerticalOffset(int index) {
    if (_dragIndex == null || _dragStartY == null || _mouseY == null) return 0;

    // Only dragged item moves vertically
    if (index == _dragIndex) {
      return _mouseY! - _dragStartY!;
    }

    return 0;  // Other items stay in place
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    
    setState(() {
      _mouseX = localPosition.dx;
      _mouseY = localPosition.dy;
      
      // Check if item should be lifted
      if (_dragIndex != null && (_mouseY! - _dragStartY!) < -10) {
        if (!_isLifted) {
          _isLifted = true;
          _draggedItem = _items[_dragIndex!];
          _items.removeAt(_dragIndex!);
        }
      }
      
      if (_dragIndex != null && _isLifted) {
        // Calculate new index based on mouse position
        final itemWidth = baseWidth + itemSpacing;
        final containerPadding = 24.0;
        final relativeX = localPosition.dx - containerPadding;
        final newIndex = (relativeX / itemWidth).round().clamp(0, _items.length);
        
        if (newIndex != _dragIndex && newIndex != _insertIndex) {
          // Cancel any ongoing animation
          _insertController.stop();
          
          _insertIndex = newIndex;
          _insertController.forward(from: 0.0);
          
          Future.delayed(_insertController.duration!, () {
            if (mounted && _insertIndex == newIndex && _draggedItem != null) {
              setState(() {
                // Only update if we're still dragging the same item
                _dragIndex = newIndex;
                _insertIndex = null;
              });
            }
          });
        }
      }
    });
  }

  // Get the current scale for the dragged item
  double _getDraggedItemScale() {
    if (_dragIndex == null || _mouseX == null) return liftedScale;  // Use larger scale when lifted
    
    final itemCenter = _getItemCenter(_dragIndex!);
    final distance = (_mouseX! - itemCenter).abs();
    const influence = 100.0;

    if (distance >= influence) return liftedScale;  // Use larger scale
    
    final t = (influence - distance) / influence;
    // Scale between maxScale and liftedScale
    return maxScale + (liftedScale - maxScale) * (1 - (1 - t) * (1 - t));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main dock
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            backgroundBlendMode: BlendMode.overlay,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: MouseRegion(
            onHover: (event) {
              if (_dragIndex == null) {
                final box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(event.position);
                setState(() => _mouseX = localPosition.dx);
              }
            },
            onExit: (_) => setState(() => _mouseX = null),
            child: GestureDetector(
              onPanStart: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                setState(() {
                  _dragStartX = localPosition.dx;
                  _dragStartY = localPosition.dy;
                  _mouseX = localPosition.dx;
                  _mouseY = localPosition.dy;
                  _dragIndex = ((localPosition.dx - 24) / (baseWidth + itemSpacing))
                      .round()
                      .clamp(0, _items.length - 1);
                });
              },
              onPanUpdate: _handleDragUpdate,
              onPanEnd: (_) => setState(() {
                _insertController.stop();
                if (_isLifted && _draggedItem != null && _dragIndex != null) {
                  // Only insert if the item isn't already in the list
                  if (!_items.contains(_draggedItem)) {
                    final insertIndex = _dragIndex!.clamp(0, _items.length);
                    _items.insert(insertIndex, _draggedItem!);
                  }
                }
                _draggedItem = null;
                _isLifted = false;
                _dragIndex = null;
                _insertIndex = null;
                _dragStartX = null;
                _dragStartY = null;
                _mouseY = null;
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => _buildDockItem(index),
                ),
              ),
            ),
          ),
        ),
        
        // Floating dragged item with identical styling
        if (_isLifted && _draggedItem != null)
          Positioned(
            left: _mouseX! - baseWidth / 2,  // Use original baseWidth for positioning
            top: _mouseY! - baseHeight / 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: baseWidth,
                height: baseHeight,
                margin: const EdgeInsets.symmetric(horizontal: itemSpacing / 2),
                child: Transform.scale(
                  scale: liftedScale,
                  alignment: Alignment.center,
                  child: DockItemWidget(item: _draggedItem!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDockItem(int index) {
    final scale = _getItemScale(index);
    
    return Transform(
      transform: Matrix4.identity()
        ..translate(baseWidth / 2, baseHeight / 2)
        ..scale(scale)
        ..translate(-baseWidth / 2, -baseHeight / 2),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        width: baseWidth,
        height: baseHeight,
        margin: const EdgeInsets.symmetric(horizontal: itemSpacing / 2),
        child: DockItemWidget(item: _items[index]),
      ),
    );
  }
}

class DockItemWidget extends StatelessWidget {
  final DockItem item;

  const DockItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.color.withOpacity(0.7),
            item.color,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Tooltip(
        message: item.label,
        child: Icon(
          item.icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
extension BoxDecorationExtension on BoxDecoration {
  BoxDecoration get withBackdrop => copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      );
}
