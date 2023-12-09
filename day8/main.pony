use "files"
use "debug"
use "collections"
use @exit[None](i: USize)
use @printf[U8](fmt: Pointer[U8] tag, ...)

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    for filename in env.args.slice(1).values() do
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.parse_file()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var linenum: USize = 0
  var count: USize = 0

  let map: Map[String, (String, String)] = Map[String, (String, String)] 
  var instructions: String val = ""
  var scratch: String ref = recover ref String end
  var currnode: String = "AAA"

  var loopmap: Map[String, (String, USize)] = Map[String, (String, USize)]

  var countb: USize = 0

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        parse_line(consume line)
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
//    reporta()
    reportb()

  be reporta() =>
    while (currnode != "ZZZ") do
      scratch = instructions.clone()
      var tnode: String = ""
      var inst: U8 = 0
      try
        while (true) do
          inst = scratch.shift()?
          tnode = currnode
          if (inst == 'L') then
            currnode = map(tnode)?._1
            Debug.out(tnode + "[L]: " + currnode)
          elseif (inst == 'R') then
            currnode = map(tnode)?._2
            Debug.out(tnode + "[R]: " + currnode)
          end
          count = count + 1
        end
      end
    end
    stdout.print("Part A Count: " + count.string())
    

  be parse_line(line: String val) => None
    if    (linenum == 0) then
      instructions = line
    elseif (linenum == 1) then 
      None
    elseif (linenum > 1) then
      Debug.out(line)
      let k: String = line.substring(0,3)
      let a: String = line.substring(7,10)
      let b: String = line.substring(12,15)
      map.insert(k, (a,b))
    end
    linenum = linenum + 1

  be reportb() =>
    /* This has to be a looping problem, so let's cache the loops */
    for k in map.keys() do
      if (k.at("A", 2)) then
        find_a_z(k)
      end
    end

    
//    for f in loopmap.values() do
      
      
  be find_a_z(k: String) =>
    Debug.out("Finding loop for " + k)
    count = 0
    currnode = k
    while (not currnode.at("Z", 2)) do
      scratch = instructions.clone()
      var tnode: String = ""
      var inst: U8 = 0
      try
        while (true) do
          inst = scratch.shift()?
          tnode = currnode
          if (inst == 'L') then
            currnode = map(tnode)?._1
            Debug.out(tnode + "[L]: " + currnode)
          elseif (inst == 'R') then
            currnode = map(tnode)?._2
            Debug.out(tnode + "[R]: " + currnode)
          end
          count = count + 1
        end
      end
    end
    loopmap.insert(k, (currnode, count))
    stdout.print(k + "->" + currnode + ": " + count.string())
    



