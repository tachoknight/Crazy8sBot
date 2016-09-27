import Foundation
import Dispatch
import CIRCBot

//
// For Linux:
//  swift build -Xswiftc -DDEBUG -Xlinker -lircclient
//

// IRC variables

struct irc_ctx_t {
    var channel = ""
    var nick = ""
}
var context = irc_ctx_t()

var session: OpaquePointer? = nil
var callbacks = UnsafeMutablePointer<irc_callbacks_t>.allocate(capacity: MemoryLayout<irc_callbacks_t>.size)

// Game variables
let backgroundQueue = DispatchQueue(label: "game.queue",
                                    attributes: .concurrent)

let serialQueue = DispatchQueue(label: "log.queue")

var gameCounter = 0

func addLog(_ logEntry: String)
{
    let currentDate = "" // Date()
    print("\(currentDate) - \(logEntry)")
}


////////////////////////////////////////////////////////////////////////////////
// G A M E  S T U F F
////////////////////////////////////////////////////////////////////////////////

// http://ericasadun.com/2016/03/08/swift-queue-fun/
public struct Queue<T>: ExpressibleByArrayLiteral {
    /// backing array store
    public private(set) var elements: Array<T> = []

    /// introduce a new element to the queue in O(1) time
    public mutating func push(_ value: T) {
        serialQueue.sync {
            elements.append(value)
        }
    }

    /// remove the front of the queue in O(`count` time
    public mutating func pop() -> T? {
        var retValue: T? = nil

        serialQueue.sync {
            if isEmpty == false {
                retValue = elements.removeFirst()
            }
        }

        return retValue
    }

    /// test whether the queue is empty
    public var isEmpty: Bool { return elements.isEmpty }

    /// queue size, computed property
    public var count: Int {
        var count: Int = 0

        serialQueue.sync {
            count = elements.count
        }
        return count
    }

    /// offer `ArrayLiteralConvertible` support
    public init(arrayLiteral elements: T...) {
        serialQueue.sync {
            self.elements = elements
        }
    }
}

var gameQueue = Queue<String>()

func showOutput(_ text: String) {
    gameQueue.push(text)
}

func broadcastGame() {
  // And now listen for the output
  var gameDone = false

  repeat {
      guard let logLine = gameQueue.pop() as Optional else {
          continue
      }

      if (logLine.contains("ZZZZZ")) {
          gameDone = true
      } else {
          irc_cmd_msg (session, context.channel, logLine)
          addLog(logLine)
      }

      #if os(Linux)
          let pauseTime = Int(random() % 8)
      #else
          let pauseTime = Int(arc4random_uniform(8) + 1)
      #endif

      sleep(UInt32(pauseTime))
  } while gameDone == false
}

func playGame(numOfPlayers: Int) {
    #if os(Linux)
        srand(UInt32(time(nil)))
    #endif

    backgroundQueue.async {
        gameCounter += 1
        let c8Game = Crazy8Game(playerCount: numOfPlayers < 4 ? numOfPlayers + 4 : numOfPlayers, gameNumber: gameCounter)
        c8Game.playGame()
        // This has to be on the async thread as well to prevent blocking
        broadcastGame()
    }
}

////////////////////////////////////////////////////////////////////////////////
// I R C  S T U F F
////////////////////////////////////////////////////////////////////////////////

func getElementsFrom(params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count:UInt32) -> [String] {
    var elements = [String]()

    let buffer = UnsafeBufferPointer(start: params, count: Int(count))
    let theArray = Array(buffer)

    for item in theArray {
        let itemBytes = UnsafePointer<Int8>(item)
        let x = String(cString:itemBytes!)
        elements.append(x)
    }

    return elements
}

func dump_event(session: Optional<OpaquePointer>, event: Optional<UnsafePointer<Int8>>, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> ()
{
    var buf = "";

    let params = getElementsFrom(params: params, count: count)
    for p in params {
        buf += " | \(p) "
    }

    let e = String(cString: (UnsafePointer<Int8>(event)!))
    var o = ""
    if let op = origin  {
        o = String(cString: UnsafePointer<Int8>(op))
    }

    addLog("\(e) \(o) \(buf)")
}

// void event_connect (irc_session_t * session, const char * event, const char * origin, const char ** params, unsigned int count)
func event_connect(session: Optional<OpaquePointer>, event: Optional<UnsafePointer<Int8>>, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> () {
    dump_event(session: session, event: event, origin: origin, params: params, count: count)

    irc_cmd_join(session, context.channel, "");
}

func event_join(session: Optional<OpaquePointer>, event: Optional<UnsafePointer<Int8>>, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> () {
    dump_event(session: session, event: event, origin: origin, params: params, count: count)

    irc_cmd_user_mode (session, "+i")
    irc_cmd_msg (session, context.channel, "Hi all - who wants to play a game of Crazy 8s?")
}

func event_channel(session: Optional<OpaquePointer>, event: Optional<UnsafePointer<Int8>>, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> () {
    if (count != 2) {
        return
    }

    let params = getElementsFrom(params: params, count: count)
    let person = String(cString: UnsafePointer<Int8>(origin)!)
    let logLine = "\(person) - \(params[0]) - \(params[1])"
    addLog(logLine)

    let textLine = params[1]
    if textLine.hasPrefix("!quit") {
        irc_cmd_quit(session, "Bye from the crazy8bot!")
        return
    }

    if textLine.hasPrefix("!play") {
        // Todo: Get the next parameter for number of players
        irc_cmd_msg (session, context.channel, "Okay! Gonna start a game with four players!")
        playGame(numOfPlayers: 4)
    }
}

func event_privmsg(session: Optional<OpaquePointer>, event: Optional<UnsafePointer<Int8>>, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> () {
    dump_event(session: session, event: event, origin: origin, params: params, count: count)
}


// void event_connect (irc_session_t * session, int event, const char * origin, const char ** params, unsigned int count)
func event_numeric(session: Optional<OpaquePointer>, event: UInt32, origin: Optional<UnsafePointer<Int8>>, params: Optional<UnsafeMutablePointer<Optional<UnsafePointer<Int8>>>>, count: UInt32) -> () {
    print("Got numeric event \(event)")
}

callbacks.pointee.event_connect = event_connect
callbacks.pointee.event_join = event_join
callbacks.pointee.event_numeric = event_numeric
callbacks.pointee.event_nick = dump_event
callbacks.pointee.event_quit = dump_event
callbacks.pointee.event_part = dump_event
callbacks.pointee.event_mode = dump_event
callbacks.pointee.event_topic = dump_event
callbacks.pointee.event_kick = dump_event
callbacks.pointee.event_channel = event_channel
callbacks.pointee.event_privmsg = event_privmsg
callbacks.pointee.event_notice = dump_event
callbacks.pointee.event_invite = dump_event
callbacks.pointee.event_umode = dump_event
callbacks.pointee.event_ctcp_rep = dump_event
callbacks.pointee.event_ctcp_action = dump_event
callbacks.pointee.event_unknown = dump_event


print("Creating session...")
session = irc_create_session(callbacks)

// Create the session...
if session == nil {
    print("Couldn't create session :(")
}

context.channel = "#zzzz5"
context.nick = "crazy8bot"

// connect
if (irc_connect(session, "irc.freenode.org", 6667, "",  context.nick, context.nick, context.nick) != 0) {
    print("Couldn't connect :(")
}

if (irc_run(session) != 0) {
    print("Hmm, got \(irc_strerror(irc_errno(session)))")
}

irc_disconnect(session)

callbacks.deallocate(capacity: MemoryLayout<irc_callbacks_t>.size)
