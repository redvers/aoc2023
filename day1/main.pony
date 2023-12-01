use "files"

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

  var total: U64 = 0

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

      report()
    else
      stdout.print("Error opening file '" + filename + "'")
    end

  be process_line(line': String iso) =>
    var index: USize = 0
    var nl: Array[U8] = recover Array[U8] end

    while (index < line'.size()) do
      try
        let s: U8 = line'.at_offset(index.isize())?
        if ((s >= '0') and (s <= '9')) then
          nl.push(s - '0')
          index = index + 1
          continue
        end
      end

      if (line'.substring(index.isize(), index.isize() + 4) == "zero") then nl.push(0) end 
      if (line'.substring(index.isize(), index.isize() + 3) == "one") then nl.push(1) end
      if (line'.substring(index.isize(), index.isize() + 3) == "two") then nl.push(2) end
      if (line'.substring(index.isize(), index.isize() + 5) == "three") then nl.push(3) end
      if (line'.substring(index.isize(), index.isize() + 4) == "four") then nl.push(4) end
      if (line'.substring(index.isize(), index.isize() + 4) == "five") then nl.push(5) end
      if (line'.substring(index.isize(), index.isize() + 3) == "six") then nl.push(6) end
      if (line'.substring(index.isize(), index.isize() + 5) == "seven") then nl.push(7) end
      if (line'.substring(index.isize(), index.isize() + 5) == "eight") then nl.push(8) end
      if (line'.substring(index.isize(), index.isize() + 4) == "nine") then nl.push(9) end

      index = index + 1
    end

    try total = total + (nl(0)? * 10).u64() + nl.apply(nl.size() - 1)?.u64() end

  be report() =>
    stdout.print(filename + ": " + total.string())

