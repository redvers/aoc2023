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
      fn.parse_cards()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var totala: USize = 0

  let numwins: Array[USize] = Array[USize]
  let numcards: Array[USize] = Array[USize]

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

    numwins.push(0)   // I really don't feel like dealing
    numcards.push(0)  // wish offsets today. i can haz cheat

  be parse_cards() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        check_card(consume line)
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end
    reporta()

  be check_card(line: String val) =>
    try
      let m: Match = Regex("^Card\\s+(\\d+): (.*) \\| (.*)$")?(line)?
      let winning: Set[USize] = extract_set(m(2)?)?
      let games: Set[USize] = extract_set(m(3)?)?

      winning.intersect(games)
      numwins.push(winning.size())
      numcards.push(1)
      let wcnt: F32 = F32(2.0).powi(winning.size().i32() - 1)
      if (wcnt >= 1) then
        totala = totala + wcnt.usize()
        Debug.out("Score: " + wcnt.string())
      else
        Debug.out("Nil points")
      end
      
    else
      Debug.out("Me went boom boom")
    end

  fun extract_set(line: String val): Set[USize] ? =>
      Debug.out(line)
      let rv: Set[USize] = Set[USize]
      for nmatch in MatchIterator(Regex("(\\d+)")?, line) do
        rv.set(nmatch(1)?.usize()?)
      end
      rv

  be reporta() =>
    stdout.print(filename + " Result: " + totala.string())
    processb()

  be processb() =>
    var cnt: USize = 1

    try
      while (cnt < numcards.size()) do
        if (false) then error end

        if (numwins(cnt)? > 0) then
          for d in Range[USize](cnt + 1, cnt + numwins(cnt)? + 1) do
            let cc: USize = numcards(d)?
            Debug.out("Increment: " + d.string() + " : " + cc.string() + " + 1")
            numcards.update(d, cc + numcards(cnt)?)?
          end
        end
          
        cnt = cnt + 1
      end
    else
      Debug.out("OOf")
    end

    cnt = 1

    var numscratchcards: USize = 0
    try
      while (cnt < numcards.size()) do
        Debug.out(cnt.string() + ": Number: " + numcards(cnt)?.string() + ", Score: " + numwins(cnt)?.string())
        numscratchcards = numscratchcards + numcards(cnt)?
        cnt = cnt + 1
      end
    else
      Debug.out("OOf")
    end

    stdout.print(filename + " Number Scratchcards: " + numscratchcards.string())

