import 'package:flutter/material.dart';
import 'package:noteapp/app_localizations.dart';
import 'package:noteapp/models/todo_model.dart';
import 'package:noteapp/models/user_model.dart';
import 'package:noteapp/providers/auth_provider.dart';
import 'package:noteapp/routes.dart';
import 'package:noteapp/services/firestore_database.dart';
import 'package:noteapp/services/todo_database_helper.dart';
import 'package:noteapp/ui/todo/empty_content.dart';
import 'package:noteapp/ui/todo/todos_extra_actions.dart';
import 'package:provider/provider.dart';

class TodosScreen extends StatelessWidget {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firestoreDatabase =
        Provider.of<FirestoreDatabase>(context, listen: false);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: StreamBuilder(
          stream: authProvider.user,
          builder: (context, snapshot) {
            final UserModel? user = snapshot.data;
            return Text(
              user != null && user.email != null
                  ? "${user.email} - ${AppLocalizations.of(context).translate("homeAppBarTitle")}"
                  : AppLocalizations.of(context).translate("homeAppBarTitle"),
            );
          },
        ),
        actions: <Widget>[
          StreamBuilder(
            stream: firestoreDatabase.todosStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<TodoModel> todos = snapshot.data as List<TodoModel>;
                return Visibility(
                  visible: todos.isNotEmpty,
                  child: TodosExtraActions(),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(Routes.setting);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.create_edit_todo);
        },
      ),
      body: PopScope(
        canPop: false,
        child: _buildBodySection(context),
      ),
    );
  }

  Widget _buildBodySection(BuildContext context) {
    final firestoreDatabase =
        Provider.of<FirestoreDatabase>(context, listen: false);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return StreamBuilder(
      stream: firestoreDatabase.todosStream(),
      builder: (context, snapshot) {
        // ✅ If Firebase has data
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            List<TodoModel> todos = snapshot.data as List<TodoModel>;

            // ✅ Cache to local DB
            DatabaseHelper().clearTodos().then((_) async {
              for (var todo in todos) {
                await DatabaseHelper().insertTodo(todo.toSqliteMap());
              }
            });

            return _buildTodoList(
                context, todos, firestoreDatabase, onSurfaceColor);
          } else {
            // ✅ No Firebase data — try loading from local DB
            return FutureBuilder<List<TodoModel>>(
              future: _loadTodosFromSQLite(),
              builder: (context, localSnapshot) {
                if (localSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (localSnapshot.hasData &&
                    localSnapshot.data!.isNotEmpty) {
                  return _buildTodoList(context, localSnapshot.data!,
                      firestoreDatabase, onSurfaceColor);
                } else {
                  return EmptyContentWidget(
                    title: AppLocalizations.of(context)
                        .translate("todosEmptyTopMsgDefaultTxt"),
                    message: AppLocalizations.of(context)
                        .translate("todosEmptyBottomMsgTxt"),
                    key: Key('EmptyContentWidget'),
                  );
                }
              },
            );
          }
        }

        // 🔁 While Firebase is connecting
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildTodoList(
    BuildContext context,
    List<TodoModel> todos,
    FirestoreDatabase firestoreDatabase,
    Color onSurfaceColor,
  ) {
    return ListView.separated(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        return Dismissible(
          background: Container(
            color: Colors.red,
            child: Center(
              child: Text(
                AppLocalizations.of(context)
                    .translate("todosDismissibleMsgTxt"),
                style: TextStyle(color: onSurfaceColor),
              ),
            ),
          ),
          key: Key(todos[index].id),
          onDismissed: (direction) {
            firestoreDatabase.deleteTodo(todos[index]);
            DatabaseHelper().deleteTodo(todos[index].id); // Sync delete

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                content: Text(
                  AppLocalizations.of(context)
                          .translate("todosSnackBarContent") +
                      todos[index].task,
                  style: TextStyle(color: onSurfaceColor),
                ),
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: AppLocalizations.of(context)
                      .translate("todosSnackBarActionLbl"),
                  textColor: onSurfaceColor,
                  onPressed: () {
                    firestoreDatabase.setTodo(todos[index]);
                    DatabaseHelper()
                        .insertTodo(todos[index].toSqliteMap()); // Sync restore
                  },
                ),
              ),
            );
          },
          child: ListTile(
            leading: Checkbox(
              value: todos[index].complete,
              onChanged: (value) {
                TodoModel todo = TodoModel(
                  id: todos[index].id,
                  task: todos[index].task,
                  extraNote: todos[index].extraNote,
                  complete: value!,
                );
                firestoreDatabase.setTodo(todo);
                DatabaseHelper()
                    .insertTodo(todo.toSqliteMap()); // ✅ Sync update
              },
            ),
            title: Text(todos[index].task),
            onTap: () {
              Navigator.of(context).pushNamed(
                Routes.create_edit_todo,
                arguments: todos[index],
              );
            },
          ),
        );
      },
      separatorBuilder: (context, index) => Divider(height: 0.5),
    );
  }

  Future<List<TodoModel>> _loadTodosFromSQLite() async {
    final todoMaps = await DatabaseHelper().getTodos();
    return todoMaps.map((map) => TodoModel.fromSqliteMap(map)).toList();
  }
}
