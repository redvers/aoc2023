# Day 1

## Problem Synopsis

The following input:

```quote
two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
```

Take the first and last number in each line to make a two digit number.

Note: The line `eightwothree` should result in `8 2 3`, so we can't just
use a Regex to `s/eight/8/` else we'll end up with `8wo3`.

Sum all of these for a final total

## Solution Methodology:

- One actor per provided filename.

- Read each file a line at a time using an iterator.  Process using behaviours
in order to allow pony's runtime to GC more frequently if needed.

- Scan each line a character at a time looking for a numeric value, or a number
in text starting at index's offset.  If either are found, insert into temporary
array.

- Take the first and last numbers in the array to generate our number and add
to a running total.

- When all lines are complete in a file, display the filename and total.


## The code

### Package Dependencies

The only package above and beyond the standard library is the "files" package.

```pony
use "files"
```

### Pony's Initial Entry

All pony programs start their execution with a single "Main" actor.  The Pony
runtime provides your program's initial entry point with an object called
`Env`.

This is the "root of trust" in your pony program.

No Pony code can access resources such as stdin, stdout, filesystem, network,
shell, environmental variables etc without an unforgeable token from this
`Env`.

The aim is to mitigate risks from supply-chain attacks. Best practice is to
provide the token that provides the minimal access to resources in order to
get the functionality needed.

Eg: An XML Parsing Library doesn't need a Network or Shell token so don't
provide it one.
                                                                              */
```pony
actor Main
  let env: Env

  new create(env': Env) =>
    env = env'
```

### Start a FileRunner Actor per filename

The provided `Env` contains the command-line arguments as provided at runtime
as an `Array[String val] val`. An immutable array of immutable strings.

- `.slice(1)` creates a copy of this array, from index 1 to the end.  Note, we
start at index of 1 because according to POSIX, the zeroth entry is the filename
of the executable itself.

- `.values()` creates an iterator object that is used by the for loop

           
```pony
    for filename in env.args.slice(1).values() do
```

Creating a reference to an Actor spawns it. The default name for an actor or class
constructor is `create`. In our case, we provide it with three arguments:

- `env.out`, this is a reference to the actor which gatekeeps the ability to
produce output to stdout.

- `FileAuth(env.root)`, this is a token that provides permission for the
spawned actor to access the filesystem.

- `filename` an immutable string containing the filename we want to process.

```pony
      let fn: FileRunner = FileRunner(env.out, FileAuth(env.root), filename)
```

### Brief aside for behaviours

A behaviour in pony is an asynchronous function call. There are no return values
because it's asyncronous - no waiting.

If you wish to model it in your head as a "message sent to an actor's mailbox
where an actor will act on each one in the order in which it is received",
then that's an excellent model to have.

As such you can think of this next call as "send to the FileRunner actor whose
reference is stored in the variable `fn`, a message that says "execute the `run()`
behaviour".

```pony
      fn.run()
		end
```

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
