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

  let instructions: Array[String val] = Array[String val]
  let lenses: Map[USize, Array[(String, USize)]] = Map[USize, Array[(String, USize)]]

  new create(stdout': OutStream tag, fileauth': FileAuth val, filename': String val) =>
    stdout = stdout'
    fileauth = fileauth'
    filename = filename'

  be parse_file() =>
    let path = FilePath(fileauth, filename)

    match OpenFile(path)
    | let file: File =>
      let lines: FileLines = FileLines(file)

      for line' in lines do
        for instr in line'.split_by(",").values() do
          instructions.push(instr)
        end
      end
    else
      stdout.print("Error opening file '" + filename + "'")
    end

    var h: USize = 0
    var suma: USize = 0
    for instr in instructions.values() do
      h = hash(0, instr)
      suma = suma + h
      Debug.out(instr + ": " + h.string())
    end
    Debug.out("SumA: " + suma.string())

    // Part B

    for instr in instructions.values() do
      apply_lens(instr)
    end


    var sum: USize = 0
    for (boxnum, contents) in lenses.pairs() do
      for (k,v) in contents.pairs() do
        var score = ((boxnum + 1) * (k + USize(1)) * v._2)
//  let lenses: Map[USize, Array[(String, USize)]] = Map[USize, Array[(String, USize)]]
        Debug.out(boxnum.string() + ": " + score.string())
        sum = sum + score
      end
    end
    Debug.out(sum.string())




  fun ref apply_lens(str: String) =>
    if (str.contains("=")) then
      Debug.out("We're an assignment")
      try
        let m: Match = Regex("^(.*)=(.*)$")?(str)?
        let boxnum: USize = hash(0, m(1)?)
        try
          update_box(m(1)?, m(2)?)?
        else
          Debug("Update box failed")
        end
      else
        Debug.out("Regex fail")
      end
    elseif (str.contains("-")) then
      Debug.out("We're a removal")
      try
        let m: Match = Regex("^(.*)-$")?(str)?
        let boxnum: USize = hash(0, m(1)?)
        try
          remove_from_box(m(1)?)?
        else
          Debug("Remove from box failed")
        end
      else
        Debug.out("Regex fail")
      end
    else
      Debug.out("Lost in the wilderness...")
    end

  fun ref remove_from_box(label: String) ? =>
    let h: USize = hash(0, label)
    var mybox: Array[(String, USize)] = lenses.get_or_else(h, Array[(String, USize)])
    lenses.insert_if_absent(h, mybox)

    var is_present: Bool = false
    var nukeptr: USize = 0

    for ptr in Range(0, mybox.size()) do
      if (mybox(ptr)?._1 == label) then
        is_present = true
        nukeptr = ptr
      end

    end
    if (not is_present) then
      Debug("Lens is not present")
    else
      Debug("Lens is deleted")
      mybox.delete(nukeptr)?
    end


//  Map[Array[(String, USize)]]
  fun ref update_box(label: String, value: String) ? =>
    let h: USize = hash(0, label)
    var mybox: Array[(String, USize)] = lenses.get_or_else(h, Array[(String, USize)])
    lenses.insert_if_absent(h, mybox)

    var is_present: Bool = false
    for ptr in Range(0, mybox.size()) do
      if (mybox(ptr)?._1 == label) then
        is_present = true
        mybox.update(ptr, (label, value.usize()?))?
      end

    end
    if (not is_present) then
      mybox.push((label, value.usize()?))
    end
        
  fun ref show_box(id: USize) =>
    Debug("\nBox Number: " + id.string())
    if (lenses.contains(id)) then
      try
        for g in (lenses(id)?.values()) do
          Debug.out(g._1 + " " + g._2.string())
        end
      else
        Debug.out("Display box has failed")
      end
    end
    



  fun hash(init': USize, str: String): USize =>
    var init: USize = init'

    try
      for ptr in Range(0, str.size()) do
        init = ((init + str(ptr)?.usize()) * 17).divrem(256)._2
      end
    else
      Debug.out("OOF")
    end
    init



/*
Determine the ASCII code for the current character of the string.
Increase the current value by the ASCII code you just determined.
Set the current value to itself multiplied by 17.
Set the current value to the remainder of dividing itself by 256.
*/




