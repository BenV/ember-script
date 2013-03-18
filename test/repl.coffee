suite 'REPL', ->

  Stream = require 'stream'

  MockInputStream = ->
    Stream.call(@)
    @
  MockInputStream.prototype = new Stream
  MockInputStream.prototype.readable = true
  MockInputStream.prototype.resume = ->
  MockInputStream.prototype.emitLine = (val) ->
    @emit 'data', new Buffer "#{val}\n"
  MockInputStream.prototype.constructor = MockInputStream

  MockOutputStream = ->
    Stream.call(@)
    @written = []
    @
  MockOutputStream.prototype = {}
  MockOutputStream.prototype.writable = true
  MockOutputStream.prototype.write = (data) ->
    @written.push data
  MockOutputStream.prototype.lastWrite = (fromEnd = -1) ->
    @written[@written.length - 1 + fromEnd].replace /\n$/, '' 
  MockOutputStream.prototype.constructor = MockOutputStream

  testRepl = (desc, fn) ->
    input = new MockInputStream
    output = new MockOutputStream
    Repl.start {input, output}
    test desc, -> fn input, output

  ctrlV = { ctrl: true, name: 'v'}


  testRepl "starts with coffee prompt", (input, output) ->
    eq 'coffee> ', output.lastWrite 0

  testRepl "writes eval to output", (input, output) ->
    input.emitLine '1+1'
    eq '2', output.lastWrite()

  testRepl "comments are ignored", (input, output) ->
    input.emitLine '1 + 1 #foo'
    eq '2', output.lastWrite()

  testRepl "output in inspect mode", (input, output) ->
    input.emitLine '"1 + 1\\n"'
    eq "'1 + 1\\n'", output.lastWrite()

  testRepl "variables are saved", (input, output) ->
    input.emitLine 'foo = "foo"'
    input.emitLine 'foobar = "#{foo}bar"'
    eq "'foobar'", output.lastWrite()

  testRepl "empty command evaluates to undefined", (input, output) ->
    input.emitLine ''
    eq 'coffee> ', output.lastWrite 0
    eq 'coffee> ', output.lastWrite()

  testRepl "ctrl-v toggles multiline prompt", (input, output) ->
    input.emit 'keypress', null, ctrlV
    eq '------> ', output.lastWrite 0
    input.emit 'keypress', null, ctrlV
    eq 'coffee> ', output.lastWrite 0

  testRepl "multiline continuation changes prompt", (input, output) ->
    input.emit 'keypress', null, ctrlV
    input.emitLine ''
    eq '....... ', output.lastWrite 0

  testRepl "evaluates multiline", (input, output) ->
    # Stubs. Could assert on their use.
    output.cursorTo = output.clearLine = ->

    input.emit 'keypress', null, ctrlV
    input.emitLine 'do ->'
    input.emitLine '  1 + 1'
    input.emit 'keypress', null, ctrlV
    eq '2', output.lastWrite()

  testRepl "variables in scope are preserved", (input, output) ->
    input.emitLine 'a = 1'
    input.emitLine 'do -> a = 2'
    input.emitLine 'a'
    eq '2', output.lastWrite()

  testRepl "existential assignment of previously declared variable", (input, output) ->
    input.emitLine 'a = null'
    input.emitLine 'a ?= 42'
    eq '42', output.lastWrite()

  testRepl "keeps running after runtime error", (input, output) ->
    input.emitLine 'a = b'
    ok 0 <= output.lastWrite().indexOf 'ReferenceError: b is not defined'
    input.emitLine 'a'
    ok 0 <= output.lastWrite().indexOf 'ReferenceError: a is not defined'
    input.emitLine '0'
    eq '0', output.lastWrite()
