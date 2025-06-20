import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String task;
  final String category;
  final bool isCompleted;

  const TaskCard({
    Key? key,
    required this.task,
    required this.category,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isCompleted ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFEBD7),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: Colors.black.withAlpha(38),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkmark box
                Container(
                  width: 24,
                  height: 24,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 2,
                        color: const Color(0xFF3F4D86),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    color: isCompleted ? const Color(0xFF3F4D86) : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 16),

                // Task Text and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Strike line
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            left: 0,
                            right: 0,
                            top: 10,
                            child: isCompleted
                                ? Container(
                                    height: 2,
                                    color: const Color(0xFF3F4D86).withOpacity(0.7),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          // Task Text
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: const Color(0xFF3F4D86),
                              fontSize: 17,
                              fontFamily: 'Allerta',
                              fontWeight: FontWeight.w400,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                            child: Text(task),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: ShapeDecoration(
                          color: const Color(0x197990F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF7990F8),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
