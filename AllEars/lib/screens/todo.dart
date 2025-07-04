import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/colors.dart';
import '../components/text.dart';
import '../models/task.dart';
import '../components/task.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // The master list of all tasks
  List<Task> tasks = [];
  // The list of tasks currently displayed by the AnimatedList
  List<Task> _animatedListItems = [];
  String searchQuery = '';
  // GlobalKey to control the AnimatedList's state for animations
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  int score = 0;

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadScore();
  }

  // This method is called when the widget's dependencies change,
  // or when the widget is rebuilt with new data.
  // We use it to synchronize _animatedListItems with filteredTasks.
  @override
  void didUpdateWidget(covariant TodoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the filtered tasks have actually changed,
    // to avoid unnecessary rebuilds and animation issues.
    final List<Task> currentFilteredTasks = filteredTasks;
    if (!listEquals(_animatedListItems, currentFilteredTasks)) {
      _updateAnimatedListItems();
    }
  }

  // Helper to compare two lists for equality (order matters)
  bool listEquals(List<Task> a, List<Task> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.json');
  }

  Future<File> get _scoreFile async {
    final path = await _localPath;
    return File('$path/score.json');
  }

  Future<void> loadTasks() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(contents);
        setState(() {
          tasks = jsonData.map((e) => Task.fromJson(e)).toList();
          // Initialize _animatedListItems after loading tasks
          _animatedListItems = List.from(filteredTasks);
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> saveTasks() async {
    final file = await _localFile;
    final jsonString = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> loadScore() async {
    try {
      final file = await _scoreFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonData = jsonDecode(contents);
        setState(() {
          score = jsonData['score'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading score: $e');
    }
  }

  Future<void> saveScore() async {
    final file = await _scoreFile;
    await file.writeAsString(jsonEncode({'score': score}));
  }

  Future<void> showAddTaskDialog() async {
    String taskText = '';
    String categoryText = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Task'),
              onChanged: (value) => taskText = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (value) => categoryText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (taskText.isNotEmpty && categoryText.isNotEmpty) {
                addTask(taskText, categoryText);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void addTask(String task, String category) {
    final newTask = Task(task: task, category: category);
    setState(() {
      tasks.insert(0, newTask); // Add to the master list at the beginning
    });

    // Check if the newly added task should be visible in the current filtered list
    // and animate its insertion if so.
    if (filteredTasks.contains(newTask)) {
      // Find the correct index for insertion in the _animatedListItems.
      // Since we insert at index 0 in `tasks`, if it's filtered, it should appear at 0.
      // This assumes `filteredTasks` maintains the original order.
      int insertIndex = 0; // New tasks are added at the top
      listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 300));
      _animatedListItems.insert(insertIndex, newTask);
    }
    saveTasks();
  }

  void fadeAndRemoveTask(int index) {
    // Get the task from the currently displayed AnimatedList items
    final Task removedTask = _animatedListItems[index];

    // Find the original index of this task in the main 'tasks' list
    final originalIndex = tasks.indexOf(removedTask);

    if (originalIndex != -1) {
      // First, animate the removal from the AnimatedList
      listKey.currentState?.removeItem(
        index, // This is the index in _animatedListItems
        (context, animation) => FadeTransition(
          opacity: animation,
          child: TaskCard(
            task: removedTask.task,
            category: removedTask.category,
            isCompleted: true, // Show as completed during fade out
          ),
        ),
        duration: const Duration(milliseconds: 500),
      );

      // Then, update the underlying data and the score
      setState(() {
        tasks.removeAt(originalIndex); // Remove from the master list
        score += 3;
      });

      // Remove from the underlying _animatedListItems list *after* calling removeItem
      // This is crucial to keep _animatedListItems in sync with what AnimatedList expects.
      _animatedListItems.removeAt(index);

      saveTasks();
      saveScore();
    }
  }

  // This method calculates the difference between the current filtered tasks
  // and the tasks currently displayed by the AnimatedList, and applies the changes.
  void _updateAnimatedListItems() {
    final List<Task> newFilteredTasks = filteredTasks;
    final List<Task> oldAnimatedListItemsCopy = List.from(_animatedListItems); // Work with a copy

    // Identify tasks to remove from _animatedListItems
    final List<Task> itemsToRemove = [];
    for (final task in oldAnimatedListItemsCopy) {
      if (!newFilteredTasks.contains(task)) {
        itemsToRemove.add(task);
      }
    }

    // Perform removals (in reverse order of current _animatedListItems to avoid index shifts)
    for (int i = oldAnimatedListItemsCopy.length - 1; i >= 0; i--) {
      final task = oldAnimatedListItemsCopy[i];
      if (itemsToRemove.contains(task)) {
        final indexInCurrentAnimatedList = _animatedListItems.indexOf(task);
        if (indexInCurrentAnimatedList != -1) {
          listKey.currentState?.removeItem(
            indexInCurrentAnimatedList,
            (context, animation) => FadeTransition(
              opacity: animation,
              child: TaskCard(
                task: task.task,
                category: task.category,
                isCompleted: false, // It's being removed, not completed
              ),
            ),
            duration: const Duration(milliseconds: 300),
          );
          _animatedListItems.removeAt(indexInCurrentAnimatedList); // Remove from our internal list
        }
      }
    }

    // Identify tasks to add to _animatedListItems
    final List<Task> itemsToAdd = [];
    for (final task in newFilteredTasks) {
      if (!_animatedListItems.contains(task)) {
        itemsToAdd.add(task);
      }
    }

    // Perform additions (maintaining original order as much as possible)
    for (final taskToAdd in itemsToAdd) {
      int insertIndex = _animatedListItems.length; // Default to end
      // Find the correct position based on the original 'tasks' list order
      // This ensures items are inserted in the same order they appear in the master list.
      for (int i = 0; i < _animatedListItems.length; i++) {
        if (tasks.indexOf(taskToAdd) < tasks.indexOf(_animatedListItems[i])) {
          insertIndex = i;
          break;
        }
      }
      listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 300));
      _animatedListItems.insert(insertIndex, taskToAdd);
    }

    // Final check for synchronization (fallback for any missed animations/edge cases)
    // This ensures _animatedListItems always perfectly reflects filteredTasks
    // after all animations and manual updates.
    if (!listEquals(_animatedListItems, newFilteredTasks)) {
      setState(() {
        _animatedListItems = List.from(newFilteredTasks);
      });
    }
  }


  List<Task> get filteredTasks {
    if (searchQuery.isEmpty) {
      return tasks;
    } else {
      final lowerCaseQuery = searchQuery.toLowerCase();
      return tasks
          .where((t) =>
              t.category.toLowerCase().contains(lowerCaseQuery) ||
              t.task.toLowerCase().contains(lowerCaseQuery)) // Search by both category and task name
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        backgroundColor: AppColors.blueRibbon,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SvgPicture.asset(
                    'assets/img/homepage/bghead.svg',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                    semanticsLabel: 'Bghead',
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Head1("To Do List", lineHeight: 1.8),
                                const SizedBox(width: 12),
                                Image.asset(
                                  'assets/img/pet/head.gif',
                                  height: 64,
                                  width: 64,
                                )
                              ],
                            ),
                            Head2(
                              'Add Task, Finish Task and Gain Score!',
                              textAlign: TextAlign.center,
                              weight: 400,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 12.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by Category or Task', // Updated label
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      // When search query changes, update the animated list
                      _updateAnimatedListItems();
                    });
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                alignment: Alignment.topCenter,
                child: _animatedListItems.isEmpty && searchQuery.isNotEmpty
                    ? const Text("No tasks found matching your search!")
                    : _animatedListItems.isEmpty && searchQuery.isEmpty
                        ? const Text("No tasks found! Add some tasks.")
                        : AnimatedList(
                            // Use the GlobalKey for AnimatedList
                            key: listKey,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            initialItemCount: _animatedListItems.length,
                            itemBuilder: (context, index, animation) {
                              final task = _animatedListItems[index];
                              return SizeTransition(
                                sizeFactor: animation,
                                child: GestureDetector(
                                  onTap: () => fadeAndRemoveTask(index),
                                  child: TaskCard(
                                    task: task.task,
                                    category: task.category,
                                    isCompleted: false,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 64.0, horizontal: 32.0),
                child: Head2(
                  'Your Score: $score',
                  textAlign: TextAlign.center,
                  weight: 600,
                  color: AppColors.blueRibbon,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
