// Generated by CoffeeScript 2.3.1
(function() {
  'use strict';
  var CND, PATH, assign, badge, debug, echo, glob, help, info, jr, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/MAIN';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  PATH = require('path');

  glob = require('globby');

  ({assign, jr} = CND);

}).call(this);

//# sourceMappingURL=recycle.js.map