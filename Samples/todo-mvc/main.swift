// Noze.io Simple Connect based TodoMVC implementation
// See: http://todomvc.com
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/todo-mvc
// - access backend via:
//     http://todobackend.com/client/index.html?http://localhost:1337/
// - test:
//     http://todobackend.com/specs/index.html?http://localhost:1337/

import http
import console
import connect
import express
import Freddy

let app = express()

// MARK: - Middleware

app.use(logger("dev"))
app.use(bodyParser.json())
app.use(cors(allowOrigin: "*"))


// MARK: - Storage

let todos = VolatileStoreCollection<Todo>()

// prefill hack
todos.objects[42] = Todo(id: 42, title: "Buy Beer",     completed: true)
todos.objects[43] = Todo(id: 43, title: "Buy Mo' Beer", completed: false)


// MARK: - Routes & Handlers

app.get("/") { req, res, _ in
  if req.accepts("json") != nil {
    res.json(todos.getAll())
  }
  else {
    let ourAPI    = "http://localhost:1337/"
    let clientURL = "http://todobackend.com/client/index.html?\(ourAPI)"
    
    res.send(
      "<html><body><h3>Welcome to the Noze.io Todo MVC Backend</h3>" +
        "<ul>" +
          "<li><a href=\"\(clientURL)\">Client</a></li>" +
        "<ul>" +
      "</body></html>"
    )
  }
}

app.del("/") { req, res, _ in
  // TBD: per spec this should to /todos/{id}, but it doesn't
  guard let json = req.body.json     else { res.sendStatus(400); return }
  guard let id = try? json.int("id") else { res.sendStatus(400); return }
  
  todos.delete(id: id)
  res.sendStatus(200)
}

app.post("/") { req, res, _ in
  guard let json = req.body.json else { res.sendStatus(400); return }
  
  // we get a POST for updates, even though the docs say PUT?
  // and it doesn't modify the URL either, which is wrong, can't PUT to the
  // collection for different items
  
  if let id = try? json.int("id") {
    // TBD: per spec this should to PUT /todos/{id}, but it doesn't
    guard var todo = todos.get(id: id) else { res.sendStatus(404); return }
    
    if let t = try? json.string("title")   { todo.title     = t }
    if let t = try? json.bool("completed") { todo.completed = t }
    todos.update(id: id, value: todo) // value type!
    
    res.json(todo)
  }
  else { // new item
    guard let t = try? json.string("title") else { res.sendStatus(400); return }
    
    let pkey = todos.nextKey()
    let newTodo = Todo(id: pkey, title: t, completed: false)
    todos.update(id: pkey, value: newTodo) // value type!
    res.status(201).json(newTodo)
  }
}

// MARK: - Run the server

app.listen(1337) {
  print("Server listening: \($0)")
}
