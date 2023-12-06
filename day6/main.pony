use "files"
use "regex"
use "debug"
use "collections"

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

  let times: Array[USize] = Array[USize]
  let distances: Array[USize] = Array[USize]

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

    Debug.out("times.size(): " + times.size().string())
    Debug.out("distances.size(): " + distances.size().string())

    var score: USize = 1
    for cnt in Range[USize](0, times.size()) do
      try score = score * (run_trial(times(cnt)?, distances(cnt)?)) end
    end
    stdout.print("Score: " + score.string())
    approx_trials(53717880, 275118112151524)
      
  fun approx_trials(t: USize, d: USize) =>
    var lower: USize = 0
    var upper: USize = t.div(2)

    var cnt: USize = 1000

    while ((cnt > 0) or ((upper-lower) > 1)) do
      Debug.out("Upper: " + upper.string() + ", Lower: " + lower.string())
      var range: USize = upper - lower
      if (approx_trial(upper, t, d)) then
        upper = (upper - range.div(2))
      else
        lower = upper
        upper = upper + range
      end
      cnt = cnt - 1
    end
    
    stdout.print("Part B: Calculated Lower Bound of Curve: " + upper.string())
    stdout.print("Part B: Calculated Upper Bound of Curve: " + (t - upper).string())
    stdout.print("Part B: Total Winning: " + (((t - upper) - upper) + 1).string())

  fun approx_trial(test: USize, time: USize, dist: USize): Bool =>
    let rt: USize = time - test
    let d: USize = test * rt
    if (d > dist) then
      Debug.out("Y: " + test.string() + "ms, " + rt.string() + "mm/s, " + d.string() + "mm")
      true
    else
      Debug.out("N: " + test.string() + "ms, " + rt.string() + "mm/s, " + d.string() + "mm")
      false
    end

  fun run_trial(time: USize, dist: USize): USize =>
    var cnt: USize = 0
    for f in Range[USize](1,time) do
      let sp: USize = f
      let rt: USize = time - f
      let d: USize = sp * rt
      if (d > dist) then
        Debug.out("Y: " + sp.string() + "ms, " + rt.string() + "mm/s, " + d.string() + "mm")
        cnt = cnt + 1
      else
        Debug.out("N: " + sp.string() + "ms, " + rt.string() + "mm/s, " + d.string() + "mm")
      end
    end
    Debug.out("Number of ways: " + cnt.string())
    cnt


  fun ref parse_line(line: String val) => None
    try
      if (Regex("^Time:")? == line) then
        for f in MatchIterator(Regex("(\\d+)")?, line) do
          times.push(f(1)?.usize()?)
        end
      end
      if (Regex("^Distance:")? == line) then
        for f in MatchIterator(Regex("(\\d+)")?, line) do
          distances.push(f(1)?.usize()?)
        end
      end
    else
      Debug.out("Unable to parse: " + line)
    end
