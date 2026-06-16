import 'package:flutter/material.dart';

class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
}

class SwipeActionTile extends StatefulWidget {
  const SwipeActionTile({
    super.key,
    required this.child,
    required this.actions,
    this.actionWidth = 88,
  });

  final Widget child;
  final List<SwipeAction> actions;
  final double actionWidth;

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile> {
  double _offset = 0;

  double get _maxOffset => widget.actions.length * widget.actionWidth;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_maxOffset, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open = _offset.abs() > _maxOffset * 0.35;
    setState(() => _offset = open ? -_maxOffset : 0);
  }

  void _close() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actions.map((action) {
                return Material(
                  color: action.color,
                  child: InkWell(
                    onTap: () {
                      _close();
                      action.onTap();
                    },
                    child: SizedBox(
                      width: widget.actionWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (action.icon != null) Icon(action.icon, color: Colors.white, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            action.label,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
