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
  List<Task> tasks = [];
  String searchQuery = '';
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  int score = 0;

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadScore();
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
      tasks.insert(0, newTask);
    });
    listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
    saveTasks();
  }

  void fadeAndRemoveTask(int index) {
    final Task removedTask = tasks[index];

    setState(() {
      tasks.removeAt(index);
      score += 3;
    });

    listKey.currentState?.removeItem(
      index,
      (context, animation) => FadeTransition(
        opacity: animation,
        child: TaskCard(
          task: removedTask.task,
          category: removedTask.category,
          isCompleted: true,
        ),
      ),
      duration: const Duration(milliseconds: 500),
    );

    saveTasks();
    saveScore();
  }

  List<Task> get filteredTasks {
    if (searchQuery.isEmpty) return tasks;
    return tasks.where((t) => t.category.toLowerCase().contains(searchQuery.toLowerCase())).toList();
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
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by Category',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                alignment: Alignment.topCenter,
                child: tasks.isEmpty
                    ? const Text("No tasks found!")
                    : AnimatedList(
                        key: listKey,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        initialItemCount: tasks.length,
                        itemBuilder: (context, index, animation) {
                          final task = tasks[index];
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
                padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 32.0),
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
