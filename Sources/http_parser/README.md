HTTP Parser
===========
![Swift](https://img.shields.io/badge/language-Swift-orange.svg?style=flat)
![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![iOS](https://img.shields.io/badge/os-iOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)

This is a parser for HTTP messages written in Swift. It parses both requests and
responses. The parser is designed to be used in performance HTTP
applications. It does not make any syscalls nor allocations, it does not
buffer data, it can be interrupted at anytime.

Features:

* No dependencies
* Handles persistent streams (keep-alive).
* Decodes chunked encoding.
* Upgrade support
* Defends against buffer overflow attacks.

The parser extracts the following information from HTTP messages:

* Header fields and values
* Content-Length
* Request method
* Response status code
* Transfer-Encoding
* HTTP version
* Request URL
* Message body


### Swift Port

It is port of the Joyent C http-parser, which in turn is based on the NGINX
parser by Igor Sysoev.
An attempt was made to keep it close to the original, which results in quite
ugly Swift, but well. The idea is to make it easier to patch in upstream changes
to the C parser.

Differences:
- callbacks are replaced with closures, which are attached to the parser
  itself (instead of being passed in as a http_parser_settings)
- we use some Swift style enums
- execute flow is different to the lack of goto's in Swift (uses nested
  functions to share access to some variables)
- no macros in Swift, hence they are replaced with funcs
- some (one-time!) allocations are done to get constant C strings
- can't use bitfields, which makes the parser object a little bigger than the
  C version

TODO:
- URL parsing is not finished
- porting bugs are inevitable, fix them


### Usage

One `HTTPParser` object is used per TCP connection. Initialize the object
and set the callbacks. That might look something like this for a request parser:
```Swift
let parser : HTTPParser(.Request)
parser.data = my_socket
parser.onURL         { p, data, len in ... }
parser.onHeaderField { p, data, len in ... }
/* ... */
```

When data is received on the socket execute the parser and check for errors.

```Swift
let len     : size_t = 80*1024
var nparsed : size_t = 0
var buf     = UnsafePointer<UInt8>.alloc(len);
var recved  : size_t = 0

recved = recv(fd, buf, len, 0);

if recved < 0 {
  /* Handle error. */
}

/* Start up / continue the parser.
 * Note we pass recved==0 to signal that EOF has been received.
 */
nparsed = parser.execute(buf, recved);

if parser.upgrade {
  /* handle new protocol */
} else if nparsed != recved {
  /* Handle error. Usually just close the connection. */
}
```

HTTP needs to know where the end of the stream is. For example, sometimes
servers send responses without Content-Length and expect the client to
consume input (for the body) until EOF. To tell http_parser about EOF, give
`0` as the second parameter to `execute()`. Callbacks and errors
can still be encountered during an EOF, so one must still be prepared
to receive them.

Scalar valued message information such as `status_code`, `method`, and the
HTTP version are stored in the parser structure. This data is only
temporally stored in `HTTPParser` and gets reset on each new message. If
this information is needed later, copy it out of the structure during the
`onHeadersComplete` callback.

The parser decodes the transfer-encoding for both requests and responses
transparently. That is, a chunked encoding is decoded before being sent to
the `onBody` callback.


The Special Problem of Upgrade
------------------------------

HTTP supports upgrading the connection to a different protocol. An
increasingly common example of this is the WebSocket protocol which sends
a request like

        GET /demo HTTP/1.1
        Upgrade: WebSocket
        Connection: Upgrade
        Host: example.com
        Origin: http://example.com
        WebSocket-Protocol: sample

followed by non-HTTP data.

(See [RFC6455](https://tools.ietf.org/html/rfc6455) for more information the
WebSocket protocol.)

To support this, the parser will treat this as a normal HTTP message without a
body, issuing both on_headers_complete and on_message_complete callbacks. However
execute() will stop parsing at the end of the headers and return.

The user is expected to check if `parser->upgrade` has been set to 1 after
`execute()` returns. Non-HTTP data begins at the buffer supplied
offset by the return value of `execute()`.


Callbacks
---------

During the `execute()` call, the callbacks set will be executed. 
The parser maintains state and
never looks behind, so buffering the data is not necessary. If you need to
save certain data for later usage, you can do that from the callbacks.

There are two types of callbacks:

* notification `typealias http_cb = ( HTTPParser ) -> Int`
    Callbacks: onMessageBegin, onHeadersComplete, onMessageComplete.
* data `typealias http_data_cb = ( HTTPParser, UnsafePointer<CChar>, size_t) -> Int`
    Callbacks: (requests only) onURL,
               (common) onHeaderField, onHeaderValue, onBody

Callbacks must return 0 on success. Returning a non-zero value indicates
error to the parser, making it exit immediately.

For cases where it is necessary to pass local information to/from a callback,
the `HTTPParser` object's `data` field can be used.
An example of such a case is when using threads to handle a socket connection,
parse a request, and then give a response over that socket. By instantiation
of a thread-local struct containing relevant data (e.g. accepted socket,
allocated memory for callbacks to write into, etc), a parser's callbacks are
able to communicate data between the scope of the thread and the scope of the
callback in a threadsafe manner. This allows http-parser to be used in
multi-threaded contexts.

Example:
```Swift
 struct custom_data_t {
  sock    : socket_t
  buffer  : UnsafePointer<Void>
  buf_len : Int
 }

...

func http_parser_thread(sock: socket_t) {
  var nparsed = 0
  /* allocate memory for user data */
  my_data : custom_data_t

  /* some information for use by callbacks.
  * achieves thread -> callback information flow */
  my_data.sock = sock

  /* instantiate a thread-local parser */
  let parser = HTTPParser(.Request) /* initialise parser */
  /* this custom data reference is accessible through the reference to the
  parser supplied to callback functions */
  parser.data = my_data;

  parser.onURL { parser, at, length in
    /* access to thread local custom_data_t struct.
    Use this access save parsed data for later use into thread local
    buffer, or communicate over socket
    */
    let ud = parser->data as! custom_data_t
    ...
    return 0;
  }

  /* execute parser */
  nparsed = parser.execute(buf, recved);

  ...
  /* parsed information copied from callback.
  can now perform action on data copied into thread-local memory from callbacks.
  achieves callback -> thread information flow */
  my_data.buffer;
  ...
}
```

In case you parse HTTP message in chunks (i.e. `read()` request line
from socket, parse, read half headers, parse, etc) your data callbacks
may be called more than once. Http-parser guarantees that data pointer is only
valid for the lifetime of callback. You can also `read()` into a heap allocated
buffer to avoid copying memory around if this fits your application.

Reading headers may be a tricky task if you read/parse headers partially.
Basically, you need to remember whether last header callback was field or value
and apply the following logic:

    (on_header_field and on_header_value shortened to on_h_*)
     ------------------------ ------------ --------------------------------------------
    | State (prev. callback) | Callback   | Description/action                         |
     ------------------------ ------------ --------------------------------------------
    | nothing (first call)   | on_h_field | Allocate new buffer and copy callback data |
    |                        |            | into it                                    |
     ------------------------ ------------ --------------------------------------------
    | value                  | on_h_field | New header started.                        |
    |                        |            | Copy current name,value buffers to headers |
    |                        |            | list and allocate new buffer for new name  |
     ------------------------ ------------ --------------------------------------------
    | field                  | on_h_field | Previous name continues. Reallocate name   |
    |                        |            | buffer and append callback data to it      |
     ------------------------ ------------ --------------------------------------------
    | field                  | on_h_value | Value for current header started. Allocate |
    |                        |            | new buffer and copy callback data to it    |
     ------------------------ ------------ --------------------------------------------
    | value                  | on_h_value | Value continues. Reallocate value buffer   |
    |                        |            | and append callback data to it             |
     ------------------------ ------------ --------------------------------------------


Parsing URLs
------------

A simplistic zero-copy URL parser is provided as `http_parser_parse_url()`.
Users of this library may wish to use it to parse URLs constructed from
consecutive `onURL` callbacks.

See examples of reading in headers:

* [partial example](http://gist.github.com/155877) in C
* [from http-parser tests](http://github.com/joyent/http-parser/blob/37a0ff8/test.c#L403) in C
* [from Node library](http://github.com/joyent/node/blob/842eaf4/src/http.js#L284) in Javascript
