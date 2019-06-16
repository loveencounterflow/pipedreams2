// Generated by CoffeeScript 2.4.1
(function() {
  'use strict';
  var $, $async, CND, PD, assign, badge, copy, debug, echo, first, help, info, isa, jr, last, rpr, select, stamp, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/DATOMS';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  ({assign, copy, jr} = CND);

  //...........................................................................................................
  types = require('./_types');

  ({isa, validate, type_of} = types);

  //...........................................................................................................
  PD = require('..');

  ({$, $async, select, stamp} = PD);

  first = Symbol('first');

  last = Symbol('last');

  //-----------------------------------------------------------------------------------------------------------
  this.$group_by = function(grouper) {
    /* TAINT, simplify, generalize, implement as standard transform `$group_by()` */
    var buffer, flush, prv_name, send;
    prv_name = null;
    buffer = null;
    send = null;
    //.........................................................................................................
    flush = () => {
      if (!((buffer != null) && buffer.length > 0)) {
        return;
      }
      send(this.new_datom('^group', {
        name: prv_name,
        value: buffer.slice(0)
      }));
      return buffer = null;
    };
    //.........................................................................................................
    return $({last}, (d, send_) => {
      var name;
      send = send_;
      if (d === last) {
        return flush();
      }
      //.......................................................................................................
      if ((name = grouper(d)) === prv_name) {
        return buffer.push(d);
      }
      //.......................................................................................................
      flush();
      prv_name = name;
      if (buffer == null) {
        buffer = [];
      }
      buffer.push(d);
      return null;
    });
  };

}).call(this);

//# sourceMappingURL=group-by.js.map