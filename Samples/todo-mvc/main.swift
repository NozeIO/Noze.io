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

var sequence = 1337

// String key to make /:id/ easier, but we don't currently see this.
var todos : [ String : Todo ] = [
  "42": Todo(id: 42, title: "Buy Beer",     completed: true),
  "43": Todo(id: 43, title: "Buy Mo' Beer", completed: false)
]


// MARK: - Routes & Handlers

app.get("/") { _, res, _ in
  res.json(Array(todos.values))
}

app.del("/") { req, res, _ in
  // TBD: per spec this should to /todos/{id}, but it doesn't
  guard let json = req.body.json     else { res.sendStatus(400); return }
  guard let id = try? json.int("id") else { res.sendStatus(400); return }
  
  todos.removeValue(forKey: String(id))
  res.sendStatus(404)
}

app.post("/") { req, res, _ in
  guard let json = req.body.json else { res.sendStatus(400); return }
  
  // we get a POST for updates, even though the docs say PUT?
  // and it doesn't modify the URL either, which is wrong, can't PUT to the
  // collection for different items
  
  if let id = try? json.int("id") {
    // TBD: per spec this should to PUT /todos/{id}, but it doesn't
    guard var todo = todos[String(id)] else { res.sendStatus(404); return }
    
    if let t = try? json.string("title")   { todo.title     = t }
    if let t = try? json.bool("completed") { todo.completed = t }
    todos[String(id)] = todo // value type!
    
    res.json(todo)
  }
  else { // new item
    guard let t = try? json.string("title") else { res.sendStatus(400); return }
    
    sequence += 1
    let newTodo = Todo(id: sequence, title: t, completed: false)
    todos[String(sequence)] = newTodo
    res.status(201).json(newTodo)
  }
}


// MARK: - Run the server

app.listen(1337) {
  print("Server listening: \($0)")
}
