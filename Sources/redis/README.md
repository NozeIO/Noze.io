Native Redis Client for Noze.io
===============================

A native, non-blocking implementation of the Redis client protocol. Supports
KVS as well as some basic pubsub. A little incomplete, but working.

Designed after [node_redis](https://github.com/NodeRedis/node_redis).

Sample

    import redis
    
    let client = redis.createClient()
    
    client.set("foo_rand00000", "OK", redis.print)
    
    client.get("foo_rand00000") { err, reply in
      console.log("Reply: \(reply)")
    }

PubSub Sample

    import redis
    
    let sub = redis.createClient(), pub = redis.createClient()
    var msg_count = 0
    
    sub.onSubscribe { channel, count in
      pub.publish("a nice channel", "I am sending a message.")
      pub.publish("a nice channel", "I am sending a second message.")
      pub.publish("a nice channel", "I am sending my last message.")
    }
    
    sub.onMessage { channel, message in
      console.log("sub channel \(channel): \(message)")"
      msg_count += 1
      if (msg_count === 3) {
        sub.unsubscribe()
        sub.quit()
        pub.quit()
      }
    }

    sub.subscribe("a nice channel")

Limitations:

- no auth
- bugs
  - not sure the replay strategy is quite right. E.g. what should happen with
    queued and sent commands when the connection goes down
- only basic commands
- no `client.multi` or `client.batch`
- no URL
- many open ends
