use "debug"
use "collections"

actor FlipFlop
  let name': String val
  let destinations: Array[(String, Node)] = Array[(String, Node)]

  var state: Bool = false

  new create(name: String val) =>
    name' = name
    Debug.out("Created FlipFlop: " + name)

  be add_destination(t: String val, node: Node) =>
    Debug.out(name' + ": Adding " + t)
    destinations.push((t, node))

    match node
    | let tt: Conjunction => tt.register_receiver(name', this)
    end

  be completed_destinations(m: FileRunner tag) =>
    m.populate_route()

/*
Flip-flop modules (prefix %) are either on or off; they are initially off. If a flip-flop module receives a high pulse, it is ignored and nothing happens. However, if a flip-flop module receives a low pulse, it flips between on and off. If it was off, it turns on and sends a high pulse. If it was on, it turns off and sends a low pulse. */

  be receive_signal(node: Node, signal: Signal) =>
    match signal
    | let s: High => return // "If a flip-flop receives a high pulse it is ignored"
    | let s: Low =>         // "If a flip-flow receives a low pulse,
      if (state) then       //  it flips between on and off.
        state = false
        emit(Low)        // If it was on, it sends a low pulse
      else
        state = true
        emit(High)       // If it was off, it sends a high pulse
      end
    end

  be emit(s: Signal) => None
    for destination in destinations.values() do
      Debug.out(name' + ": Sends " + s.string() + " -> " + destination._1)
      destination._2.receive_signal(this, s)
    end

actor Conjunction
  let name': String val
  let destinations: Array[(String, Node)] = Array[(String, Node)]

  let inputmap: MapIs[Node, Signal] = MapIs[Node, Signal]

  new create(name: String val) =>
    name' = name
    Debug.out("Created Conjunction: " + name)

  be add_destination(t: String val, node: Node) =>
    Debug.out(name' + ": Adding " + t)
    destinations.push((t, node))

    match node
    | let tt: Conjunction => tt.register_receiver(name', this)
    end

  be completed_destinations(m: FileRunner tag) =>
    m.populate_route()

  be register_receiver(t: String, node: Node) =>
    inputmap.insert(node, Low) // FIXME

/* Conjunction modules (prefix &) remember the type of the most recent pulse received from each of their connected input modules; they initially default to remembering a low pulse for each input. When a pulse is received, the conjunction module first updates its memory for that input. Then, if it remembers high pulses for all inputs, it sends a low pulse; otherwise, it sends a high pulse. */

  be receive_signal(node: Node, signal: Signal) =>
    inputmap.update(node, signal) // When a pulse is received, it first updates memory
                                  // for that input

    var allhigh: Bool = true
    for input in inputmap.values() do
      match input
      | let t: High => None // Checking for all high
      | let t: Low  => allhigh = false
      end
    end

    if (allhigh) then
      emit(Low)
    else
      emit(High)
    end

  be emit(s: Signal) => None
    for destination in destinations.values() do
      Debug.out(name' + ": Sends " + s.string() + " -> " + destination._1)
      destination._2.receive_signal(this, s)
    end

actor Broadcast
  let name': String val
  let destinations: Array[(String, Node)] = Array[(String, Node)]

  new create(name: String val) =>
    name' = name
    Debug.out("Created Broadcast: " + name)

  be add_destination(t: String val, node: Node) =>
    Debug.out(name' + ": Adding " + t)
    destinations.push((t, node))

    match node
    | let tt: Conjunction => tt.register_receiver(name', this)
    end

  be completed_destinations(m: FileRunner tag) =>
    m.populate_route()

/* There is a single broadcast module (named broadcaster). When it receives a pulse, it sends the same pulse to all of its destination modules. */ 

  be receive_signal(node: Node, signal: Signal) =>
    emit(signal)

  be emit(s: Signal) => None
    for destination in destinations.values() do
      Debug.out(name' + ": Sends " + s.string() + " -> " + destination._1)
      destination._2.receive_signal(this, s)
    end

actor Null
  let name': String val

  new create(name: String val) =>
    name' = name
    Debug.out("Created Broadcast: " + name)

  be add_destination(t: String val, node: Node) =>
    Debug.out("Never Happens")

  be completed_destinations(m: FileRunner tag) =>
    Debug.out("Still never happens")

  be receive_signal(node: Node, signal: Signal) =>
    Debug.out("We count, no emission")

  be emit(s: Signal) => None

type Node is (FlipFlop | Conjunction | Broadcast | Null)

primitive High fun string(): String => "High"
primitive Low fun string():  String => "Low"
type Signal is (High | Low)
