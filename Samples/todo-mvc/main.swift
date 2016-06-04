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

let ourAPI = "http://localhost:1337/"

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

app.get("/*") { req, res, _ in
  if req.accepts("json") != nil {
    res.json(todos.getAll())
  }
  else {
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

app.del("/todos/:id") { req, res, _ in
  guard let id = req.params[int: "id"] else { res.sendStatus(400); return }
  todos.delete(id: id)
  res.sendStatus(200)
}

app.patch("/todos/:id") { req, res, _ in
  guard let id   = req.params[int: "id"] else { res.sendStatus(404); return }
  guard let json = req.body.json         else { res.sendStatus(400); return }
  guard var todo = todos.get(id: id)     else { res.sendStatus(404); return }

  if let t = try? json.string("title")   { todo.title     = t }
  if let t = try? json.bool("completed") { todo.completed = t }
  todos.update(id: id, value: todo) // value type!
  
  res.json(todo)
}

app.post("/*") { req, res, _ in
  guard let json = req.body.json else { res.sendStatus(400); return }
  
  guard let t = try? json.string("title") else { res.sendStatus(400); return }
  
  let pkey = todos.nextKey()
  let newTodo = Todo(id: pkey, title: t, completed: false)
  todos.update(id: pkey, value: newTodo) // value type!
  res.status(201).json(newTodo)
}

// MARK: - Run the server

app.listen(1337) {
  print("Server listening: \($0)")
}
