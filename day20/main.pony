use "files"
use "debug"
use "regex"
use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    for filename in env.args.slice(1).values() do
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.run()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var cnt: USize = 0
  var firstnode: String val = ""

  var actormap: Map[String val, (Node, Array[String val])] = Map[String val, (Node, Array[String val])]
  var actorarray: Array[String val] = Array[String val]

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be run() => None
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        process_line(consume line)
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end

    populate_route()

  be process_line(line': String val) =>
    try
      let m: Match = Regex("^(.*) -> (.*)")?(line')?
      let nodename: String val = m(1)?
      let nodedef: String trn = m(2)?.clone()
      nodedef.replace(" ", "")

      if (cnt == 0) then
        firstnode = nodename
      end
      cnt = cnt + 1

      let nn: String val = nodename.substring(1)

      match nodename(0)?
      | let t: U8 if (t == '%') => let ff: FlipFlop = FlipFlop(nn)
          let a: Array[String val] = (consume nodedef).split_by(",")
          actormap.insert(nn, (ff, a))
          actorarray.push(nn)
      | let t: U8 if (t == '&') => let cj: Conjunction = Conjunction(nn)
          let a: Array[String val] = (consume nodedef).split_by(",")
          actormap.insert(nn, (cj, a))
          actorarray.push(nn)
      | let t: U8 if (t == 'b') => let br: Broadcast = Broadcast(m(1)?)
          let a: Array[String val] = (consume nodedef).split_by(",")
          actormap.insert(m(1)?, (br, a))
          actorarray.push(m(1)?)
      else
        Debug.out("Unknown type: " + line')
      end
    else
      Debug.out("Bad regex")
    end

  be populate_route() =>
    try
      let t: String val = actorarray.shift()?
      Debug.out("Setting Destinations for: " + t)
      let v: (Node, Array[String val]) = actormap(t)?
      for target in v._2.values() do
        try
          v._1.add_destination(target, actormap(target)?._1)
        else
          v._1.add_destination(target, Null(target))
          Debug.out("Created a Null Node for  " + target)
        end
      end
      v._1.completed_destinations(this)
    else
      Debug.out("Finished populating")
      start_run()
    end
  

  be start_run() =>
    try
      actormap("broadcaster")?._1.receive_signal(FlipFlop("null"), Low)
    else
      Debug.out("Unable to send button press")
    end
  

//  var actormap: Map[String val, (Node, Array[String val])] = Map[String val, (Node, Array[String val])]
