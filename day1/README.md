# Day 1
      
```ponyc
use "files"

/*
    All pony programs enter with a single "Main" actor.  Pony passes one
  argument, the "environment" which is used to control access to resources.

    More of this later...
                                                                              */
actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

/*
    env.args an array of Strings (Array[String]), the command line arguments

    .slice(1) creates a copy of this array, from index 1 to the end.
    .values() creates an iterator object that is used by the for loop
                                                                              */
    for filename in env.args.slice(1).values() do

/* 
    We spawn a new "FileRunner" actor for every filename that is provided
  on the command-line. This results in all the files being processed in
  parallell.

    Pony's security model restricts access to resources such as files, network,
  shell, environmental variables etc by using unforgable tokens.  We pass two
  of these tokens and the filename to the FileRunner actor during creation.

    env.out is a reference to an actor that allows you to print to standard out
    FileAuth is a token that allows access to the filesystem.
                                                                              */
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
      fn.run()
		end


actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

//We're going to keep our running total as an instance variable in this actor
  var total: U64 = 0

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be run() => None
//  Open the file for reading
    let path = FilePath(fileauth, filename)

//  We either get a File object, or something else, if the file can't be opened.
    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line in lines do
        // We send every line in the file as a message to ourself
        process_line(consume line)
      end

      // After all the lines have been queued, which queues up report AFTER THEM
      report()
    else
      stdout.print("Error opening file '" + filename + "'")
    end

  be process_line(line': String iso) =>
/*
    Lines like eightwone should result in 8 2 1. If we just used substitution
  then the result would be 8 w 1.                                             */
    var index: USize = 0

//  As numbers are found, we add them to an Array[U8]
    var nl: Array[U8] = recover Array[U8] end

    while (index < line'.size()) do
      try
        // s is the ASCII encoding of the character at index
        let s: U8 = line'.at_offset(index.isize())?

        /*
          If the ASCII value is between the ASCII values '0' and '9', add the
          actual values to the array
                                                                              */
        if ((s >= '0') and (s <= '9')) then
          nl.push(s - '0')
          index = index + 1
          continue
        end
      end

    // Scan and insert if the strings are found
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

    /*
        Convert the first and last number in the temporary array into a two digit number
      and add it to the total
                                                                              */
    try total = total + (nl(0)? * 10).u64() + nl.apply(nl.size() - 1)?.u64() end

/*
    After all the lines are processed, print out the filename and total
                                                                              */
  be report() =>
    stdout.print(filename + ": " + total.string())
```
