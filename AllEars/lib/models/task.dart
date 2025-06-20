class Task {
  final String task;
  final String category;

  Task({required this.task, required this.category});

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        task: json['task'],
        category: json['category'],
      );

  Map<String, dynamic> toJson() => {
        'task': task,
        'category': category,
      };
}
