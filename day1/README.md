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

### The FileRunner Actor

#### constructor

The `FileRunner` actor stores as instance variables the provided arguments and the
running total:

- `stdout`, the reference to the actor that gatekeeps stdout.

- `fileauth`, the unforgable token that provides access to the filesystem.

- `filename`, the filename to open and process.

- `total`, A U64 (unsigned 64 bit integer)

```pony
actor FileRunner
  let stdout: OutStream tag
  let fileauth: FileAuth val
  let filename: String val

  var total: U64 = 0

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

```

#### run(), (and an aside about runtime errors)

As Pony is strongly typed and protected from unsafe memory operations by using
refcaps (we'll talk about that later...), the aim is to catch as many bugs
during compilation as opposed to at runtime.

In other less-strict languages, bugs can be created by things like not checking
return values when doing things like opening files that you don't have permission
to open.

Pony forces you to deal with failures with typing:

In the `files` package, when you try to open a file for reading, your return
value is either `File`, or `FileErrNo`.  As you can't perform file operations
on a `FileErrNo`, the compiler forces you to ensure that at runtime your
`OpenFile` returned a `File`.

`match` matches types:

```pony
  be run() => None
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
.
.
.
    else
      stdout.print("Error opening file '" + filename + "'")
    end
```

In the successful path where a File is returned, we loop through each line
and send it as a message to ourselves where they will be processed one line
at a time.

```pony
      for line in lines do
        process_line(consume line)
      end
```

Once all the lines are sent, we send a `report()` message which, since actors
ALWAYS process these behaviours in the order received, will happen after the
last line is processed.

```pony
      report()
```

#### process_line, where all the magic happens...

This implements the methodology described in the first section. It should be
fairly readable:

- `line'`, the line we're processing as an immutable string.

- `index`, the position in the `line'` String that we are currently analyzing.

- `nl`, A new Array of U8 (unsigned 8 bit numbers) which represent each found number

```pony
  be process_line(line': String iso) =>
    var index: USize = 0
    var nl: Array[U8] = recover Array[U8] end
```

We loop when our index is less than the size of the array.

```pony
    while (index < line'.size()) do
      try
```

We set the ASCII value of the character at the location indicated by index.

```pony
        let s: U8 = line'.at_offset(index.isize())?
```

We branch if the ASCII value for s is between the ASCII value for 0 and 9,
inclusive.  If they are, we subtract the ASCII value for '0' from s and
push that into `nl`.  This works of course because 0-9 and consecutive in
the ASCII table.

Increment index.

Go around the loop again.

```pony
        if ((s >= '0') and (s <= '9')) then
          nl.push(s - '0')
          index = index + 1
          continue
        end
      end
```

Instead of using regexes, we just have a series of if-then cases to look for
the textual representations of the numbers.

Increment the index and back around the loop we go:

```pony
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
```

The next case is to take the first and last numbers, convert to a two-digit number and
add to the running total.  But what happens if there are no numbers and the array is
empty?

Pony forces you to make a decision. If we try and read a value which is out of the
range of the Array it will raise an error.

We wrap the math in a try - end, because if there's no numbers present - we don't
need to add anything.

```pony
    try total = total + (nl(0)? * 10).u64() + nl.apply(nl.size() - 1)?.u64() end
```

#### report(), the final display

Once all the lines have been processed, we send a message to the actor which
gatekeeps stdout to print out our results.

```pony
  be report() =>
    stdout.print(filename + ": " + total.string())
```

## Final Note

Remember that as each file is processed by a different actor, the order in which
the results are displayed is not deterministic.
