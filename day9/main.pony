use "files"
use "debug"
use "regex"
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

  var lineno: USize = 0
  var linemap: Map[USize, Array[Array[ISize]]] = Map[USize, Array[Array[ISize]]]

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
    reporta()

  be reporta() =>
    var parta: ISize = 0
    for p in linemap.keys() do
      try resolve_line(p)? end
      try insert_next_vals(p)? end
      try parta = parta + linemap(p)?(0)?(linemap(p)?(0)?.size() - 1)? end
    end
    stdout.print(filename + " ScoreA: " + parta.string())

    var partb: ISize = 0
    for p in linemap.keys() do
      try insert_prev_vals(p)? end
      try partb = partb + linemap(p)?(0)?(0)? end
    end
    stdout.print(filename + " ScoreB: " + partb.string())

  fun ref insert_prev_vals(line': USize) ? =>
    let linedata: Array[Array[ISize]] = linemap(line')?
    var rankcntr: USize = linedata.size() - 2

    while (rankcntr >= 0) do
      Debug.out("BEFORE: " + debug_line(linedata(rankcntr)?))
      let firstval: ISize = linedata(rankcntr)?(0)?
      let lvcd: ISize = linedata(rankcntr + 1)?(0)?
      linedata(rankcntr)?.unshift(firstval - lvcd)
      Debug.out("AFTER:  " + debug_line(linedata(rankcntr)?))

      rankcntr = rankcntr - 1
    end

  fun ref insert_next_vals(line': USize) ? =>
    let linedata: Array[Array[ISize]] = linemap(line')?
    var rankcntr: USize = linedata.size() - 2

    while (rankcntr >= 0) do
      Debug.out("BEFORE: " + debug_line(linedata(rankcntr)?))
      let lastval: ISize = linedata(rankcntr)?(linedata(rankcntr)?.size() - 1)?
      let lvcd: ISize = linedata(rankcntr + 1)?(linedata(rankcntr + 1)?.size() - 1)?
      linedata(rankcntr)?.push(lastval + lvcd)
      Debug.out("AFTER:  " + debug_line(linedata(rankcntr)?))

      rankcntr = rankcntr - 1
    end



  fun ref resolve_line(line': USize) ? =>
    let linedata: Array[Array[ISize]] = linemap(line')?

    var linecnt: USize = 0
    while (difference_calculator(linedata, linecnt)?) do
      linecnt = linecnt + 1
    end

  fun ref difference_calculator(linedata: Array[Array[ISize]], rank: USize): Bool ? =>
    Debug.out("Processing: " + debug_line(linedata(rank)?))
    var myval: ISize = linedata(rank)?(0)?
    var newline: Array[ISize] = Array[ISize]
    var cnt: USize = 1

    var zerodetect: ISize = 0

    while (cnt < linedata(rank)?.size()) do
      newline.push(linedata(rank)?(cnt)? - myval)
      zerodetect = (zerodetect + linedata(rank)?(cnt)?) - myval
      myval = linedata(rank)?(cnt)?
      cnt = cnt + 1
    end
    linedata.push(newline)
    if (zerodetect == 0) then false else true end

  fun debug_line(l: Array[ISize]): String val =>
    var rv: String trn = recover trn String end
    for f in l.values() do
      rv.append(f.string() + ",")
    end
    consume rv

  be parse_line(line: String val) => None
    let linearray: Array[Array[ISize]] = Array[Array[ISize]]
    let linezero: Array[ISize] = Array[ISize]
    try
      for f in MatchIterator(Regex("(\\-*\\d+)")?, line) do
        linezero.push(f(1)?.isize()?)
      end
    else
        Debug.out("I have issues")
    end
    linearray.push(linezero)
    linemap.insert(lineno, linearray)
    lineno = lineno + 1

