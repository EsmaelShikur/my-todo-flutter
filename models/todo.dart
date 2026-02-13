class Todo {
  String title;
  bool isCompleted;

  Todo({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(title: json['title'], isCompleted: json['isCompleted']);
  }
}
