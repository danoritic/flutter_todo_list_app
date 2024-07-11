import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'memory_analyst.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

Color mainTextColor = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF31325A),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Todo List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseHelper todoDBHandler = DatabaseHelper(
      fieldString: 'todoID int,text TEXT,date TEXT,isComplete INTEGER',
      tableName: 'todoList',
      dbName: 'todoList.db');
  int _counter = 0;
  List listOfCompletedTasks = [];
  List listOfAllTasks = [];
  @override
  void initState() {
    // todoDBHandler.clearTable("todoList");
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      listOfAllTasks = await todoDBHandler.getAll("todoList");
      setState(() {});
      // for (Map<String, dynamic> i in listOfAllTasks) {
      //   if (i["isComplete"]) {
      //     listOfCompletedTasks.add(i);
      //   }
      // }
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  int? selectedChip = 0;
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF31325A),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                height: 50,
                width: MediaQuery.of(context).size.width * .9,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Stack(children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 50.0, left: 20),
                      child: TextField(
                        onAppPrivateCommand: controller.text.isNotEmpty
                            ? (value, map) async {
                                await todoDBHandler.insert({
                                  "todoID": const Uuid().v4(),
                                  "text": value,
                                  "isComplete": 0
                                }, "todoList");

                                print(listOfAllTasks);
                                listOfAllTasks =
                                    await todoDBHandler.getAll("todoList");
                                controller.text = "";
                                setState(() {});
                              }
                            : (value, map) {},
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: controller.text.isNotEmpty
                            ? (value) async {
                                await todoDBHandler.insert({
                                  "todoID": const Uuid().v4(),
                                  "text": value,
                                  "isComplete": 0
                                }, "todoList");

                                print(listOfAllTasks);
                                listOfAllTasks =
                                    await todoDBHandler.getAll("todoList");
                                controller.text = "";
                                setState(() {});
                              }
                            : (value) {},
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        controller: controller,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        style: ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Theme.of(context).colorScheme.primary)),
                        color: Colors.white,
                        onPressed: controller.text.isNotEmpty
                            ? () async {
                                await todoDBHandler.insert({
                                  "todoID": const Uuid().v4(),
                                  "text": controller.text,
                                  "isComplete": 0
                                }, "todoList");

                                print(listOfAllTasks);
                                listOfAllTasks =
                                    await todoDBHandler.getAll("todoList");
                                controller.text = "";
                                setState(() {});
                              }
                            : () {},
                        icon: const Icon(
                          Icons.add,
                          size: 15,
                        ),
                      ),
                    )
                  ]),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .04,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buidChip(label: "All", index: 0),
                  const SizedBox(width: 20),
                  _buidChip(label: "Completed", index: 1),
                  const SizedBox(width: 20),
                  _buidChip(label: "Incompleted", index: 2),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .04,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ((selectedChip == 0)
                        ? listOfAllTasks
                        : (selectedChip == 1)
                            ? listOfAllTasks
                                .where((element) => element['isComplete'] == 1)
                            : listOfAllTasks
                                .where((element) => element["isComplete"] == 0))
                    .map((e) {
                  print("e" * 120);
                  print(e);
                  return Column(
                    children: [
                      TodoWidget(
                        isInitiallySelected: () {
                          print(e?["isComplete"] == 1);
                          return e?["isComplete"] == 1;
                        }.call(),
                        text: e?["text"],
                        date: e?["date"] ?? "",
                        onSelectFunction: (value) async {
                          await todoDBHandler.database?.update(
                              "todoList", {"isComplete": (value) ? 1 : 0},
                              where: "todoID = ?", whereArgs: [e["todoID"]]);
                          listOfAllTasks =
                              await todoDBHandler.getAll("todoList");
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 10)
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buidChip({int? index, required String label}) {
    return SizedBox(
      height: 40,
      child: ChoiceChip(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        side: BorderSide.none,
        shape: null,
        label: Text(label),
        selected: selectedChip == index,
        onSelected: (value) async {
          selectedChip = index;
          listOfAllTasks = await todoDBHandler.getAll("todoList");
          setState(() {});
        },
      ),
    );
  }
}

class TodoWidget extends StatefulWidget {
  String date;

  TodoWidget({
    super.key,
    required this.isInitiallySelected,
    required this.text,
    required this.date,
    required this.onSelectFunction,
  });
  bool isInitiallySelected;
  String text;
  Function(bool) onSelectFunction;

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  bool isSelected = true;

  @override
  void initState() {
    // TODO: implement initState
    isSelected = widget.isInitiallySelected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isSelected = widget.isInitiallySelected;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Container(
            height: 30,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
            child: IconButton(
                iconSize: 10,
                onPressed: () {
                  isSelected = true;
                  widget.onSelectFunction.call(isSelected);
                  setState(() {});
                },
                padding: const EdgeInsets.all(0),
                color: isSelected
                    ? Colors.green.withAlpha(100)
                    : Colors.transparent,
                icon: Icon(
                  Icons.check,
                  size: 17,
                  color: isSelected ? Colors.green : Colors.transparent,
                )),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * .03),
          Text(
            widget.text,
            style: TextStyle(
                color: mainTextColor,
                fontWeight: FontWeight.bold,
                decorationColor: Colors.white,
                decorationStyle: TextDecorationStyle.wavy,
                decorationThickness: 2,
                decoration: isSelected ? TextDecoration.lineThrough : null),
          ),
          const Expanded(child: SizedBox()),
          Text(
            widget.date,
            style: const TextStyle(color: Colors.blue),
          ),
        ]),
      ),
    );
  }
}
