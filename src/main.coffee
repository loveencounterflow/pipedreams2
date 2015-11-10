

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS2'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
### https://github.com/dominictarr/event-stream ###
ES                        = @_ES = require 'event-stream'
#...........................................................................................................
### https://github.com/dominictarr/sort-stream ###
@$sort                    = require 'sort-stream'
#...........................................................................................................
### https://github.com/dominictarr/stream-combiner ###
combine                   = require 'stream-combiner'
#...........................................................................................................
@new_densort              = ( DS = require './densort' ).new_densort.bind DS
PIPEDREAMS                = @
LODASH                    = CND.LODASH
#...........................................................................................................
### http://stringjs.com ###
S                         = require 'string'



#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
# @create_readstream            = HELPERS.create_readstream             .bind HELPERS
# @create_readstream_from_text  = HELPERS.create_readstream_from_text   .bind HELPERS
# @pimp_readstream              = HELPERS.pimp_readstream               .bind HELPERS
# @merge                        = ES.merge                              .bind ES
@$split                       = ES.split                              .bind ES
$map                          = ES.map                                .bind ES
# @$chain                       = ES.pipeline                           .bind ES
# @through                      = ES.through                            .bind ES
# @duplex                       = ES.duplex                             .bind ES
# @as_readable                  = ES.readable                           .bind ES
# @read_list                    = ES.readArray                          .bind ES

# #-----------------------------------------------------------------------------------------------------------
# D.$map_plus = ( transform ) ->
#   ### TAINT looks like `write` occurs too late or `end` too early ###
#   ### Like `map`, but calls `transform` one more time (hence the name) with `undefined` in place of data
#   just before the stream has ended; this gives the caller one more chance to send data. ###
#   R = ES.map transform # ( data, handler ) -> transform data, handler
#   _end = R.end.bind R
#   R.end = ->
#     transform undefined, ( error, data ) ->
#       return R.error error if error?
#       debug '©GbYu0', data
#       R.write data if data?
#       setImmediate _end
#   return R


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self ) ->
    R             = (  data ) -> self.emit 'data',  data # if data?
    R.error       = ( error ) -> self.emit 'error', error
    R.end         =           -> self.emit 'end'
    R.pause       =           -> self.pause()
    R.resume      =           -> self.resume()
    R.read        =           -> self.read()
    # R[ '%self' ]  = self
    R.stream      = self
    return R
  #.....................................................................................................
  on_data = ( data ) ->
    send = get_send @ unless send?
    method data, send
  #.........................................................................................................
  switch arity = method.length
    when 2
      null
    #.......................................................................................................
    when 3
      on_end = ->
        send  = get_send @ unless send?
        end   = => @emit 'end'
        method undefined, send, end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  return ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@remit_async = ( method ) ->
  unless ( arity = method.length ) is 2
    throw new Error "expected a method with an arity of 2, got one with an arity of #{arity}"
  return $map ( input_data, handler ) =>
    ### TAINT should add `done.end`, `done.pause` and so on ###
    done        = ( output_data ) => if output_data? then handler null, output_data else handler()
    done.error  = ( error )       => handler error
    method input_data, done

#-----------------------------------------------------------------------------------------------------------
$       = @remit.bind @
$async  = @remit_async.bind @


#===========================================================================================================
# COMBINING STREAM TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@combine = ( transforms... ) ->
  return combine transforms...


#===========================================================================================================
# EXPERIMENTAL: STREAM LINKING, CONCATENATING
#-----------------------------------------------------------------------------------------------------------
@$continue = ( stream ) ->
  return $ ( data, send, end ) =>
    stream.write data
    if end?
      stream.end()
      end()

# #-----------------------------------------------------------------------------------------------------------
# @$link = ( transforms... ) ->
#   return @create_throughstream() if transforms.length is 0
#   source  = sink = @create_throughstream()
#   sink    = sink.pipe transform for transform in LODASH.flatten transforms
#   _send   = null
#   sink.on 'data', ( data ) => _send data
#   return $ ( data, send ) =>
#     _send = send
#     source.write data

#-----------------------------------------------------------------------------------------------------------
D.create_fitting = ( transforms, settings ) ->
  ###

  ## Motivation

  Building stream pipelines often happens by concatenating (as far as the resulting stream is
  concerned) anonymous stream transforms with chanins of `.pipe()` calls, and often this approach is
  appropriate and sufficient: figuratively, an assembly line with an input end for raw data and an
  output end for processed data is being constructed, and all that matters is that a complex
  transformation is deined in neat steps and wrapped up with a snazzy handle such as 'parse Markdown
  source and turn it to HTML'.

  Especially as transforms grow more complex, however, we often want to adapt existing pipelines to
  varied new uses, keep tabs on what's going on at intermediate points, re-inject data at specific
  points, or deal with meta data that may only become avaible at some time during processing. Such needs
  are then often dealt with by way of custom-built `create_xxxstream` methods whose call signatures and
  return values are each a law upon itself. The author of this has himself experimented with creating
  throughstreams that got extended with custom attributes, sometimes making use of ES6 Symbols to hide
  such extensions from the stream API proper, which always felt more like an expedient than a solution.
  `PIPEDREAMS.create_fitting` has been written to support a more principled approach, and, in fact,
  `create_fitting` as such does almost nothing by itself, as a look at its source will show:

  ```coffee
  @create_fitting = ( transforms, settings ) ->
    confluence  = if ( CND.isa_list transforms ) then ( D.combine transforms... ) else transforms
    input       = settings?[ 'input'  ] ? @create_throughstream()
    output      = settings?[ 'output' ] ? @create_throughstream()
    input
      .pipe confluence
      .pipe output
    R =
      '~isa':       'PIPEDREAMS/fitting'
      input:        input
      output:       output
      inputs:       if settings[ 'inputs'  ]? then CND.LODASH.clone settings[ 'inputs'  ] else {}
      outputs:      if settings[ 'outputs' ]? then CND.LODASH.clone settings[ 'outputs' ] else {}
    return R
  ```

  ## Usage

  Given a list of `transforms` (i.e. intermediate streams) and an optional `settings` object,
  derive input, transformation and output from these givens and return a `PIPEDREAMS/fitting` object with
  the following entries:

  * `input`: the reading side of the pipeline; this will be `settings[ 'input' ]` where present, or else
    a newly created throughstream;
  * `output`: the writing side of the pipeline; either `settings[ 'output' ]` or a new stream;
  * `inputs`: a copy of `settings[ 'inputs' ]` or a blank object;
  * `outputs`: a copy of `settings[ 'outputs' ]` or a blank object.

  The `inputs` and `outputs` members of the fitting are a mere convenience, a convention meant to aid
  in mainting consistent APIs. The consumer of `create_fitting` is responsible to populate these entries
  in a meaningful way.


  ## Example

  As a simple demonstration how to use `create_fitting`, here's a function that defines three transforms
  to perform addition, multiplication and squaring of some numeric data, and that define extra input
  and output points, made available as `fitting[ 'inputs' ][ 'add' ]` and
  `fitting[ 'outputs' ][ 'unsquared' ]`, respectively:

  ```coffee
  #-------------------------------------------------------------
  create_frob_fitting = ( settings ) ->
    multiply      = $ ( data, send ) => send data * 2
    add           = $ ( data, send ) => send data + 2
    square        = $ ( data, send ) => send data ** 2
    unsquared     = D.create_throughstream()
    #...........................................................
    inputs        = { add, }
    outputs       = { unsquared, }
    transforms    = [ multiply, add, unsquared, square, ]
    #...........................................................
    return D.create_fitting transforms, { inputs, outputs, }
  ```

  Observe that while we have chosen to define the processing pipeline as a list of stream transforms,
  we could have just as well sent in the result of consecutive `.pipe()` calls.

  Here's how to use our new frob fitting: we keep an eye on all the data that passes through the pipeline
  at the point before it gets squared; also, we want to re-inject a value of `-10` (into the input point
  labelled `add`) whenever the pipeline yields a `100`; having set up the workings so far, we then
  write our source data into the input:

  ```coffee
  #-------------------------------------------------------------
  fitting = create_frob_fitting()
  { input, output, inputs, outputs, } = fitting
  outputs[ 'unsquared' ].pipe $ ( data, send ) -> help 'unsquared:', data
  output
    .pipe $ ( data, send ) ->
      inputs[ 'add' ].write -10 if data is 100
      send data
    .pipe D.$show()
  input.write n for n in [ 1 ... 10 ]
  ```

  ###
  confluence  = if ( CND.isa_list transforms ) then ( D.combine transforms... ) else transforms
  input       = settings?[ 'input'  ] ? @create_throughstream()
  output      = settings?[ 'output' ] ? @create_throughstream()
  input
    .pipe confluence
    .pipe output
  R =
    '~isa':       'PIPEDREAMS/fitting'
    input:        input
    output:       output
    inputs:       if settings[ 'inputs'  ]? then CND.LODASH.clone settings[ 'inputs'  ] else {}
    outputs:      if settings[ 'outputs' ]? then CND.LODASH.clone settings[ 'outputs' ] else {}
  return R


#-----------------------------------------------------------------------------------------------------------
@$lockstep = ( input, settings ) ->
  ### Usage:

  ```coffee
  input_1
    .pipe D.$lockstep input_2 # or `.pipe D.$lockstep input_2, fallback: null`
    .pipe $ ( [ data_1, data_2, ], send ) =>
      ...
  ```

  `$lockstep` combines each piece of data coming down the stream with one piece of data emitted from the
  stream you passed in when calling the function. If the two streams turn out to have unequal lengths,
  an error is sent into the stream unless you called the function with an additional `fallback: value`
  argument.
  ###
  #.........................................................................................................
  fallback  = settings?[ 'fallback' ]
  idx_1     = 0
  idx_2     = 0
  buffer_1  = []
  buffer_2  = []
  _send     = null
  _end_1    = null
  _end_2    = null
  #.........................................................................................................
  flush = =>
    #.......................................................................................................
    if _send?
      while ( buffer_1.length > 0 ) and ( buffer_2.length > 0 ) and idx_1 is idx_2
        _send [ buffer_1.shift(), buffer_2.shift(), ]
        idx_1 += +1
        idx_2 += +1
    #.......................................................................................................
    if _end_1? and _end_2?
      if ( buffer_1.length > 0 ) or ( buffer_2.length > 0 )
        for idx in [ 0 ... Math.max buffer_1.length, buffer_2.length ]
          data_1 = buffer_1[ idx ]
          data_2 = buffer_2[ idx ]
          if data_1 is undefined or data_2 is undefined
            if fallback is undefined
              return _send.error new Error "streams of unequal lengths and no fallback value given"
            data_1 = fallback if data_1 is undefined
            data_2 = fallback if data_2 is undefined
          _send [ data_1, data_2, ]
      _end_1()
      _end_2()
  #.........................................................................................................
  input.on 'data', ( data_2 ) =>
    buffer_2.push data_2
    flush()
  #.........................................................................................................
  input.pipe @$on_end ( end ) =>
    _end_2 = end
    flush()
  #.........................................................................................................
  return $ ( data_1, send, end ) =>
    _send   = send
    #.......................................................................................................
    if data_1?
      buffer_1.push data_1
      flush()
    #.......................................................................................................
    if end?
      _end_1 = end
      flush()


#===========================================================================================================
# OMITTING VALUES
#-----------------------------------------------------------------------------------------------------------
@$skip_first = ( n = 1 ) ->
  count = 0
  return $ ( data, send ) ->
    count += +1
    send data if count > n


#===========================================================================================================
# SPECIALIZED STREAMS
#-----------------------------------------------------------------------------------------------------------
@create_throughstream = ( P... ) ->
  # R           = through2.obj P...
  ### TAINT `end` events passed through synchronously even when `write` happens asynchronously ###
  R           = ES.through P...
  write       = R.write.bind R
  end         = R.end.bind R
  #.........................................................................................................
  R.write = ( data, handler ) ->
    if handler?
      setImmediate ->
        handler null, write data
    else
      return write data
  #.........................................................................................................
  R.end = ( handler ) ->
    if handler?
      setImmediate ->
        handler null, end()
    else
      return end()
  #.........................................................................................................
  R.setMaxListeners 0
  return R

#-----------------------------------------------------------------------------------------------------------
@spawn_and_read = ( P... ) ->
  readstream_from_spawn     = require 'spawn-to-readstream'
  spawn                     = ( require 'child_process' ).spawn
  return readstream_from_spawn spawn P...

#-----------------------------------------------------------------------------------------------------------
@spawn_and_read_lines = ( P... ) ->
  last_line = null
  R         = @create_throughstream()
  input     = @spawn_and_read P...
  #.........................................................................................................
  input
    .pipe @$split()
    .pipe $ ( line, send, end ) =>
      #.....................................................................................................
      if line?
        R.write last_line if last_line?
        last_line = line
      #.....................................................................................................
      if end?
        R.write last_line if last_line? and last_line.length > 0
        R.end()
        end()
  #.........................................................................................................
  return R


#===========================================================================================================
# NO-OP
#-----------------------------------------------------------------------------------------------------------
@$pass_through = -> $ ( data, send ) -> send data


#===========================================================================================================
# SUB-STREAMS
#-----------------------------------------------------------------------------------------------------------
@$sub = ( sub_transformer ) ->
  #.........................................................................................................
  _send   = null
  # _end    = null
  cache   = undefined
  #.........................................................................................................
  source        = @create_throughstream()
  sink          = @create_throughstream()
  state         = {}
  source.ended  = false
  sub_transformer source, sink, state
  #.........................................................................................................
  sink.on   'data', ( data )  => _send data
  sink.on   'end',            => _send.end()
  #.........................................................................................................
  return $ ( data, send, end ) =>
    if data?
      _send = send
      if cache is undefined
        cache = data
      else
        source.write cache
        cache = data
    if end?
      source.ended = true
      source.write cache unless cache is undefined


#===========================================================================================================
# SORT AND SHUFFLE
#-----------------------------------------------------------------------------------------------------------
@$densort = ( key = 1, first_idx = 0, report_handler = null ) ->
  ds        = @new_densort key, first_idx, report_handler
  has_ended = no
  #.........................................................................................................
  # send_data = ( send, data ) =>
  #.........................................................................................................
  signal_end = ( send ) =>
    send.end() unless has_ended
    has_ended = yes
  #.........................................................................................................
  return $ ( input_data, send, end ) =>
    #.......................................................................................................
    if input_data?
      ds input_data, ( error, output_data ) =>
        return send.error error if error?
        send output_data
    #.......................................................................................................
    if end?
      ds null, ( error, output_data ) =>
        return send.error error if error?
        if output_data? then  send output_data
        else                  signal_end send

#-----------------------------------------------------------------------------------------------------------
# @$shuffle =

#===========================================================================================================
# SAMPLING / THINNING OUT
#-----------------------------------------------------------------------------------------------------------
@$sample = ( p = 0.5, options ) ->
  ### Given a `0 <= p <= 1`, interpret `p` as the *p*robability to *p*ick a given record and otherwise toss
  it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
  `$sample 0.5` (the default) will toss (on average) every other record.

  You can pipe several `$sample()` calls, reducing the data stream to 50% with each step. If you know
  your data set has, say, 1000 records, you can cut down to a random sample of 10 by piping the result of
  calling `$sample 1 / 1000 * 10` (or, of course, `$sample 0.01`).

  Tests have shown that a data file with 3'722'578 records (which didn't even fit into memory when parsed)
  could be perused in a matter of seconds with `$sample 1 / 1e4`, delivering a sample of around 370
  records. Because these records are randomly selected and because the process is so immensely sped up, it
  becomes possible to develop regular data processing as well as coping strategies for data-overload
  symptoms with much more ease as compared to a situation where small but realistic data sets are not
  available or have to be produced in an ad-hoc, non-random manner.

  **Parsing CSV**: There is a slight complication when your data is in a CSV-like format: in that case,
  there is, with `0 < p < 1`, a certain chance that the *first* line of a file is tossed, but some
  subsequent lines are kept. If you start to transform the text line into objects with named values later in
  the pipe (which makes sense, because you will typically want to thin out largeish streams as early on as
  feasible), the first line kept will be mis-interpreted as a header line (which must come first in CSV
  files) and cause all subsequent records to become weirdly malformed. To safeguard against this, use
  `$sample p, headers: true` (JS: `$sample( p, { headers: true } )`) in your code.

  **Predictable Samples**: Sometimes it is important to have randomly selected data where samples are
  constant across multiple runs:

  * once you have seen that a certain record appears on the screen log, you are certain it will be in the
    database, so you can write a snippet to check for this specific one;

  * you have implemented a new feature you want to test with an arbitrary subset of your data. You're
    still tweaking some parameters and want to see how those affect output and performance. A random
    sample that is different on each run would be a problem because the number of records and the sheer
    bytecount of the data may differ from run to run, so you wouldn't be sure which effects are due to
    which causes.

  To obtain predictable samples, use `$sample p, seed: 1234` (with a non-zero number of your choice);
  you will then get the exact same
  sample whenever you re-run your piping application with the same stream and the same seed. An interesting
  property of the predictable sample is that—everything else being the same—a sample with a smaller `p`
  will always be a subset of a sample with a bigger `p` and vice versa. ###
  #.........................................................................................................
  unless 0 <= p <= 1
    throw new Error "expected a number between 0 and 1, got #{rpr p}"
  #.........................................................................................................
  ### Handle trivial edge cases faster (hopefully): ###
  return ( $ ( record, send ) => send record ) if p == 1
  return ( $ ( record, send ) => null        ) if p == 0
  #.........................................................................................................
  headers = options?[ 'headers'     ] ? false
  seed    = options?[ 'seed'        ] ? null
  count   = 0
  rnd     = rnd_from_seed seed
  #.........................................................................................................
  return $ ( record, send ) =>
    count += 1
    send record if ( count is 1 and headers ) or rnd() < p


#===========================================================================================================
# AGGREGATION & DISSEMINATION
#-----------------------------------------------------------------------------------------------------------
@$aggregate = ( initial_value, on_data, on_end = null ) ->
  ### `$aggregate` allows to compose stream transformers that act on the entire stream. Aggregators may

  * replace all data items with a single item;
  * observe the entire stream and either add or print out summary values.

  `$aggregate` should be called with two or three arguments:
  * `initial_value` is the base value that represents the value of the aggregator when it never
    gets to see any data; for a count or a sum that would be `0`, for a list of all data items, that would
    be an empty list, and so on.
  * `on_data` is the handler for each data items. It will be called as `on_data data, send`. Whatever
    value the data handler returns becomes the next value of the aggregator. If you want to *keep* data
    ittems in the stream, you must call `send data`; if you want to *omit* data items (and maybe later on
    replace them with the aggregate), do not call `send data`.
  * `on_end`, when given, will be called as `on_end current_value, send` after the last data item has come
    down the stream, but before `end` is emitted on the stream. It gives you the chance to perform some
    data transformation on your aggregate. If `on_end` is not given, the default operation is to just send
    on the current value of the aggregate.

  See `$count` and `$collect` for examples of aggregators.

  Note that unlike `Array::reduce`, handlers will not be given much context; it is your obligation to do
  all the bookkeeping—which should be a simple and flexible thing to implement using JS closures.
  ###
  current_value = initial_value
  return $ ( data, send, end ) =>
    if data?
      current_value = on_data data, send
    if end?
      if on_end? then on_end current_value, send else send current_value
      end()

#-----------------------------------------------------------------------------------------------------------
@$count = ( on_end = null ) ->
  count = 0
  #.........................................................................................................
  on_data = ( data, send ) ->
    send data
    return count += +1
  #.........................................................................................................
  return @$aggregate count, on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$collect = ( on_end = null ) ->
  collector = []
  #.........................................................................................................
  on_data = ( data, send ) ->
    collector.push data
    return collector
  #.........................................................................................................
  return @$aggregate collector, on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  end       = settings?[ 'end'      ] ? no
  return $ ( data, send ) =>
    unless type = ( CND.type_of data ) is 'list'
      return send.error new Error "expected a list, got a #{rpr type}"
    for value, idx in data
      send if indexed then [ idx, value, ] else value
    send null if end

#-----------------------------------------------------------------------------------------------------------
@$batch = ( batch_size = 1000 ) ->
  throw new Error "buffer size must be non-negative integer, got #{rpr batch_size}" if batch_size < 0
  buffer = []
  #.........................................................................................................
  return $ ( data, send, end ) =>
    if data?
      buffer.push data
      if buffer.length >= batch_size
        send buffer
        buffer = []
    if end?
      send buffer if buffer.length > 0
      end()


#===========================================================================================================
# STREAM START & END DETECTION
#-----------------------------------------------------------------------------------------------------------
# @$signal_end = ( signal = @eos ) ->
#   ### Given an optional `signal` (which defaults to `null`), return a stream transformer that emits
#   `signal` as last value in the stream. Observe that whatever value you choose for `signal`, that value
#   should be gracefully handled by any transformers that follow in the pipe. ###
#   on_data = null
#   on_end  = ->
#     @emit 'data', signal
#     @emit 'end'
#   return ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$on_end = ( method ) ->
  ### TAINT use `$map` to turn this into an async method? ###
  switch arity = method.length
    when 0, 1, 2 then null
    else throw new Error "expected method with arity 1 or 2, got one with arity #{arity}"
  return $ ( data, send, end ) ->
    send data if data?
    if end?
      if arity is 0
        method()
        return end()
      return method end if arity is 1
      method send, end

#-----------------------------------------------------------------------------------------------------------
@$on_start = ( method ) ->
  is_first = yes
  return $ ( data, send ) ->
    method send if is_first
    is_first = no
    send data


#===========================================================================================================
# FILTERING
#-----------------------------------------------------------------------------------------------------------
@$filter = ( method ) ->
  return $ ( data, send ) =>
    send data if method data

# #-----------------------------------------------------------------------------------------------------------
# @$take_last_good = ( method ) ->
#   last_data = null
#   return $ ( data, send, end ) =>
#     if data?
#       if method data
#       last_data = data
#     if end?
#       end()

#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = CND.get_logger 'info', badge ? '*'
  return $ ( record, send ) =>
    my_show rpr record
    send record

#-----------------------------------------------------------------------------------------------------------
@$observe = ( method ) ->
  ### Call `method` for each piece of data; when `method` has returned with whatever result, send data on.
  Essentially the same as a `$filter` transform whose method always returns `true`. ###
  # return @$filter ( data ) -> method data; return true
  switch arity = method.length
    when 1
      return $ ( data, send ) =>
        method data
        send data
    when 2
      return $ ( data, send, end ) =>
        if data?
          method data, false
          send data
        if end?
          method undefined, true
          end()
    else throw new Error "expected method with arity 1 or 2, got one with arity #{arity}"

#-----------------------------------------------------------------------------------------------------------
@$stop_time = ( badge_or_handler ) ->
  t0 = null
  return @$observe ( data, is_last ) =>
    t0 = +new Date() if data? and not t0?
    if is_last
      dt = ( new Date() ) - t0
      switch type = CND.type_of badge_or_handler
        when 'function'
          badge_or_handler dt
        when 'text', 'jsundefined'
          logger = CND.get_logger 'info', badge_or_handler ? 'stop time'
          logger "#{(dt / 1000).toFixed 2}s"
        else
          throw new Error "expected function or text, got a #{type}"


#===========================================================================================================
# THROUGHPUT LIMITING
#-----------------------------------------------------------------------------------------------------------
@$throttle_bytes = ( bytes_per_second ) ->
  Throttle = require 'throttle'
  return new Throttle bytes_per_second

#-----------------------------------------------------------------------------------------------------------
@$throttle_items = ( items_per_second ) ->
  buffer    = []
  count     = 0
  idx       = 0
  _send     = null
  timer     = null
  has_ended = no
  #.........................................................................................................
  emit = ->
    if ( data = buffer[ idx ] ) isnt undefined
      buffer[ idx ] = undefined
      idx   += +1
      count += -1
      _send data
    #.......................................................................................................
    if has_ended and count < 1
      clearInterval timer
      _send.end()
      buffer = _send = timer = null # necessary?
    #.......................................................................................................
    return null
  #.........................................................................................................
  start = ->
    timer = setInterval emit, 1 / items_per_second * 1000
  #---------------------------------------------------------------------------------------------------------
  return $ ( data, send, end ) =>
    if data?
      unless _send?
        _send = send
        start()
      buffer.push data
      count += +1
    #.......................................................................................................
    if end?
      has_ended = yes


#===========================================================================================================
# CSV
#-----------------------------------------------------------------------------------------------------------
@$parse_csv = ( options ) ->
  field_names = null
  options    ?= {}
  headers     = options[ 'headers'    ] ? true
  delimiter   = options[ 'delimiter'  ] ? ','
  qualifier   = options[ 'qualifier'  ] ? '"'
  #.........................................................................................................
  return @remit ( record, send ) =>
    if record?
      values = ( S record ).parseCSV delimiter, qualifier, '\\'
      if headers
        if field_names is null
          field_names = values
        else
          record = {}
          record[ field_names[ idx ] ] = value for value, idx in values
          send record
      else
        send values


#===========================================================================================================
# ERROR HANDLING
#-----------------------------------------------------------------------------------------------------------
@run = ( method, handler ) ->
  domain  = ( require 'domain' ).create()
  domain.on 'error', ( error ) -> handler error
  setImmediate -> domain.run method
  return domain


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
get_random_integer = ( rnd, min, max ) ->
  return ( Math.floor rnd() * ( max + 1 - min ) ) + min

#-----------------------------------------------------------------------------------------------------------
rnd_from_seed = ( seed ) ->
  return if seed? then CND.get_rnd seed else Math.random



#===========================================================================================================
# EXPERIMENTAL
# #-----------------------------------------------------------------------------------------------------------
# @_$send_later = ->
#   #.........................................................................................................
#   R     = D.create_throughstream()
#   count = 0
#   _end  = null
#   #.....................................................................................................
#   send_end = =>
#     if _end? and count <= 0
#       _end()
#     else
#       setImmediate send_end
#   #.....................................................................................................
#   R
#     .pipe $ ( data, send, end ) =>
#       if data?
#         count += +1
#         setImmediate =>
#           count += -1
#           send data
#           debug '©MxyBi', count
#       if end?
#         _end = end
#   #.....................................................................................................
#   send_end()
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @_$pull = ->
#   queue     = []
#   # _send     = null
#   is_first  = yes
#   pull = ->
#     if queue.length > 0
#       return queue.pop()
#     else
#       return [ 'empty', ]
#   return $ ( data, send, end ) =>
#     if is_first
#       is_first = no
#       send pull
#     if data?
#       queue.unshift [ 'data', data, ]
#     if end?
#       queue.unshift [ 'end', end, ]

# #-----------------------------------------------------------------------------------------------------------
# @_$take = ->
#   return $ ( pull, send ) =>
#     # debug '©vKkJf', pull
#     # debug '©vKkJf', pull()
#     process = =>
#       [ type, data, ] = pull()
#       # debug '©bamOB', [ type, data, ]
#       switch type
#         when 'data'   then send data
#         when 'empty'  then null
#         when 'end'    then return send.end()
#         else send.error new Error "unknown event type #{rpr type}"
#       setImmediate process
#     process()




