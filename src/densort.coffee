


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2/densort'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
# #...........................................................................................................
# BNP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'



#-----------------------------------------------------------------------------------------------------------
module.exports = new_densort = ( key = 1, first_idx = 0, report_handler = null ) ->
  ### Given up to three arguments—a `key`, a `first_idx`, and a `report_handler`—return a function that
  will accept a series of indexed elements and a callback function which it will call with all the elements
  ordered according to their ascending indices.

  The motivation for this function is the observation that in order to sort a stream of elements, it is in
  the general case necessary to buffer *all* elements before they can be sorted and sent on. This is because
  in the general case it is unknown prior to stream completion whether or not yet another element that will
  fit into any given position is pending; for example, if you queried a database for a list of words to
  be sorted alphabetically, it is, generally, not possible to decide whether between any two words—say,
  `'train'` and `'trainspotter'`—a third word is due, say, `'trains'`. This is because the sorting criterion
  (i.e. the sequence of letters of each word) is 'sparse'.

  I love trains, but i don't like the fact that i will always have to backup potentially large streams in
  memory before i can go on with processing.

  Fortunately, there is an important class of cases that provide 'dense' sorting criterion coupled with
  moderate disorder among the elements: Consider a stream that originates from a database query similar to
  `SELECT INDEX(), word FROM words ORDER BY word ASC` (where `INDEX()` is a function to add a zero-based row
  index to each record in the result set); we want to send each record to a consumer over a [network
  connection][1], one record at a time. We can then be reasonably sure that that the order of items arriving
  at the consumer is *somewhat* correlated to their original order; at the same time, we may be justified in
  suspecting that *some* items have swapped places; in other words, the `INDEX()` field in each record will
  be very similar to a monotonically growing series.

    [1] In fact, some network connections—e.g. one using WebSockets—is indeed order-preserving, but it's
    easy to imagine a transport protocol (like UDP) that isn't, or a query result that is assembled from
    asynchronous calls to a database where each call originated from one piece of data in the stream.

  This is where `densort` comes in: assuming records are offered in a 'dense' fashion, with some field of
  the recording containing an integer index `i`, forming a finite series with a definite lower bound `i0`
  and a certain number of elements `n` such that the index of the last element is `i1 = n + i0` and each
  index `i` in the range `i0 <= i <= i1` is associated with exactly one record.

  Given a stream of `data` items with an index available as `data[ key ]`, re-emit data items in order
  such that indexes are ordered, and no items are left out. This is is called 'dense sort' as it presupposes
  that no single index is left out of the sequence, such that whenever an item with index `n` is seen, it
  can be passed on as soon as all items with index m < n have been seen and passed on. Conversely, any item
  whose predecessors have not yet been seen and passed on must be buffered. The method my be called as
  `$densort k, n0`, where `k` is the key to pick up the index from each data item (defaulting to `1`,
  i.e. assuming an 'element list' whose first item is the index element name, the second is the index, and
  the rest represents the payload), and `n0` is the lowest index (defaulting to `0` as
  well).

  In contradistinction to 'agnostic' sorting (which must buffer all data until the stream has ended), the
  hope in a dense sort is that buffering will only ever occur over few data items which should hold as long
  as the stream originates from a source that emitted items in ascending order over a reasonably 'reliable'
  network (i.e. one that does not arbitrarily scramble the ordering of packages); however, it is always
  trivial to cause the buffering of *all* data items by withholding the first data item until all others
  have been sent; thus, the performance of this method cannot be guaranteed.

  To ensure data integrity, this method will throw an exception if the stream should end before all items
  between `n0` and the last seen index have been sent (i.e. in cases where the stream was expected to be
  dense, but turned out to be sparse), and when a duplicate index has been detected.

  You may pass in a `handler` that will be called after the entire stream has been processed; that function,
  if present, will be called with a pair `[ n, m, ]` where `n` is the total number of elements encountered,
  and `m <= n` is the maximal number of elements that had to be buffered at any one single point in time.
  `m` will equal `n` if the logically first item happened to arrive last (and corresponds to the number of
  items that have to be buffered with 'sparse', agnostic sorting); `m` will be zero if all items happened
  to arrive in their logical order (the optimal case). ###
  #.........................................................................................................
  key_is_function = TYPES.isa_function key
  buffer          = []
  buffer_size     = 0             # Amount of buffered items
  previous_idx    = first_idx - 1 # Index of most recently sent item
  smallest_idx    = Infinity      # Index of first item in buffer
  min_legal_idx   = 0             # 'Backlog' of the range of indexes that have already been sent out
  max_buffer_size = 0
  element_count   = 0
  sent_count      = 0
  #.........................................................................................................
  buffer_element = ( idx, element ) =>
    throw new Error "duplicate index #{rpr idx}" if buffer[ idx ]?
    smallest_idx  = Math.min smallest_idx, idx
    # debug '<---', smallest_idx
    buffer[ idx ] = element
    buffer_size  += +1
    return null
  #.........................................................................................................
  send_buffered_elements = ( handler ) =>
    ### Refuse to send anything unless all elements with smaller indexes have already been sent: ###
    return if sent_count < ( smallest_idx - first_idx )
    loop
      ### Terminate loop in case nothing is in the buffer or we have reached an empty position: ###
      if buffer_size < 1 or not ( element = buffer[ smallest_idx ] )?
        # smallest_idx    = Infinity if buffer_size < 1
        min_legal_idx   = Math.max min_legal_idx, smallest_idx
        break
      #.....................................................................................................
      ### Remove element to be sent from buffer (making it a sparse list in most cases), adjust sentinels and
      send element: ###
      delete buffer[ smallest_idx ]
      previous_idx    = smallest_idx
      max_buffer_size = Math.max max_buffer_size, buffer_size
      smallest_idx   += +1
      buffer_size    += -1
      sent_count     += +1
      min_legal_idx   = Math.max min_legal_idx, smallest_idx
      handler null, element
  #.........................................................................................................
  return ( element, handler ) =>
    #.......................................................................................................
    if element?
      element_count += +1
      idx            = if key_is_function then key element else element[ key ]
      if idx < min_legal_idx # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        warn 'buffer_size:      ', buffer_size
        warn 'max_buffer_size:  ', max_buffer_size
        warn 'min_legal_idx:    ', min_legal_idx
        warn 'previous_idx:     ', previous_idx
        warn 'smallest_idx:     ', smallest_idx
        warn buffer
      throw new Error "duplicate index #{rpr idx}" if idx < min_legal_idx
      #.....................................................................................................
      if buffer_size is 0 and idx is previous_idx + 1
        previous_idx    = idx
        min_legal_idx   = idx + 1
        sent_count     += +1
        smallest_idx    = Infinity if buffer_size < 1
        handler null, element
      #.....................................................................................................
      else
        buffer_element idx, element
        send_buffered_elements handler
    #.......................................................................................................
    else
      send_buffered_elements handler
      if buffer_size > 0 # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # warn 'first_idx:        ', first_idx
        # warn 'element_count:    ', element_count
        # warn 'sent_count:       ', sent_count
        warn 'buffer_size:      ', buffer_size
        warn 'max_buffer_size:  ', max_buffer_size
        warn 'min_legal_idx:    ', min_legal_idx
        warn 'previous_idx:     ', previous_idx
        warn 'smallest_idx:     ', smallest_idx
        warn buffer
      throw new Error "detected missing elements" if buffer_size > 0
      report_handler [ element_count, max_buffer_size, ] if report_handler?
      handler null, null



