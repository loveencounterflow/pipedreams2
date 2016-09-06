// Generated by CoffeeScript 1.10.0
(function() {
  var $, $as_event, $as_row, $async, $cleanup, $dividers, $set_widths_etc, CND, D, _new_state, alert, as_row, as_text, badge, boxes, copy, debug, get_divider, help, keys_toplevel, ref, rpr, to_width, urge, values_alignment, values_overflow, warn, width_of;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/PLUGIN-TABULATE';

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  D = require('./main');

  $ = D.$, $async = D.$async;

  ref = require('to-width'), to_width = ref.to_width, width_of = ref.width_of;

  this.$tabulate = function(settings) {
    var S, pipeline;
    if (settings == null) {
      settings = {};
    }
    S = _new_state(settings);
    pipeline = [$as_event(S), $set_widths_etc(S), $dividers(S), $as_row(S), $cleanup(S)];
    return this.new_stream({
      pipeline: pipeline
    });
  };

  this.$show_table = function(settings) {
    throw new Error("not implemented");
  };

  _new_state = function(settings) {
    var S, box_style, ref1, ref10, ref11, ref12, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9;
    S = {};

    /* TAINT better to use formal schema here? */
    D._validate_keys("settings", "one or more out of", Object.keys(settings), keys_toplevel);
    S.width = (ref1 = settings['width']) != null ? ref1 : 12;
    S.alignment = (ref2 = settings['alignment']) != null ? ref2 : 'left';

    /*
    process.stdout.columns
     */
    S.fit = (ref3 = settings['fit']) != null ? ref3 : null;
    S.ellipsis = (ref4 = settings['ellipsis']) != null ? ref4 : '…';
    S.pad = (ref5 = settings['pad']) != null ? ref5 : ' ';
    S.overflow = (ref6 = settings['overflow']) != null ? ref6 : 'show';
    S.alignment = (ref7 = settings['alignment']) != null ? ref7 : 'left';
    S.widths = copy((ref8 = settings['widths']) != null ? ref8 : []);
    S.alignments = (ref9 = settings['alignments']) != null ? ref9 : [];
    S.headings = (ref10 = settings['headings']) != null ? ref10 : true;
    S.keys = (ref11 = settings['keys']) != null ? ref11 : null;
    S.box = copy((ref12 = settings['box']) != null ? ref12 : copy(boxes['plain']));
    if (CND.isa_number(S.pad)) {
      S.pad = ' '.repeat(S.pad);
    }
    if (CND.isa_text(S.box)) {
      S.box = box_style = boxes[S.box];
    }
    if (S.box == null) {
      throw new Error("unknown box style " + (rpr(box_style)));
    }
    S.box.left = S.box.vs + S.pad;
    S.box.center = S.pad + S.box.vs + S.pad;
    S.box.right = S.pad + S.box.vs;
    S.box.left_width = width_of(S.box.left);
    S.box.center_width = width_of(S.box.center);
    S.box.right_width = width_of(S.box.right);
    D._validate_keys("alignment", "one of", [S.alignment], values_alignment);
    D._validate_keys("overflow", "one of", [S.overflow], values_overflow);
    if (S.overflow !== 'show') {
      throw new Error("setting 'overflow' not yet supported");
    }
    if (S.fit != null) {
      throw new Error("setting 'fit' not yet supported");
    }

    /* TAINT check widths etc. are non-zero integers */

    /* TAINT check values in headings, widths, keys (?) */
    return S;
  };

  keys_toplevel = ['alignment', 'alignments', 'box', 'default', 'ellipsis', 'fit', 'headings', 'keys', 'overflow', 'pad', 'width', 'widths'];

  values_overflow = ['show', 'hide'];

  values_alignment = ['left', 'right', 'center'];

  $set_widths_etc = function(S) {
    return $('first', function(event, send) {
      var _, base, base1, data, i, idx, j, key, mark, ref1, ref2;
      mark = event[0], data = event[1];
      if (mark !== 'data') {
        return send(event);
      }
      if (S.keys == null) {
        if (CND.isa_list(data)) {
          S.keys = (function() {
            var i, len, results;
            results = [];
            for (idx = i = 0, len = data.length; i < len; idx = ++i) {
              _ = data[idx];
              results.push(idx);
            }
            return results;
          })();
        } else if (CND.isa_pod(data)) {
          S.keys = (function() {
            var results;
            results = [];
            for (key in data) {
              results.push(key);
            }
            return results;
          })();
        } else {
          return send.error(new Error("expected a list or a POD, got a " + (CND.type_of(data))));
        }
      }
      if (S.headings === true) {
        S.headings = S.keys;
      }
      if (S.widths != null) {
        for (idx = i = 0, ref1 = S.keys.length; 0 <= ref1 ? i < ref1 : i > ref1; idx = 0 <= ref1 ? ++i : --i) {
          if ((base = S.widths)[idx] == null) {
            base[idx] = S.width;
          }
        }
      } else {
        S.widths = (function() {
          var j, len, ref2, results;
          ref2 = S.keys;
          results = [];
          for (j = 0, len = ref2.length; j < len; j++) {
            key = ref2[j];
            results.push(S.width);
          }
          return results;
        })();
      }
      if (S.alignments != null) {
        for (idx = j = 0, ref2 = S.keys.length; 0 <= ref2 ? j < ref2 : j > ref2; idx = 0 <= ref2 ? ++j : --j) {
          if ((base1 = S.alignments)[idx] == null) {
            base1[idx] = S.alignment;
          }
        }
      } else {
        S.alignments = (function() {
          var k, len, ref3, results;
          ref3 = S.keys;
          results = [];
          for (k = 0, len = ref3.length; k < len; k++) {
            key = ref3[k];
            results.push(S.alignment);
          }
          return results;
        })();
      }
      return send(event);
    });
  };

  as_row = (function(_this) {
    return function(S, data, keys) {
      var R, align, ellipsis, i, idx, key, keys_and_idxs, len, ref1, text, width;
      if (keys == null) {
        keys = null;
      }
      R = [];
      if (keys != null) {
        keys_and_idxs = (function() {
          var i, len, results;
          results = [];
          for (idx = i = 0, len = keys.length; i < len; idx = ++i) {
            key = keys[idx];
            results.push([key, idx]);
          }
          return results;
        })();
      } else {
        keys_and_idxs = (function() {
          var i, ref1, results;
          results = [];
          for (idx = i = 0, ref1 = data.length; 0 <= ref1 ? i < ref1 : i > ref1; idx = 0 <= ref1 ? ++i : --i) {
            results.push([idx, idx]);
          }
          return results;
        })();
      }
      for (i = 0, len = keys_and_idxs.length; i < len; i++) {
        ref1 = keys_and_idxs[i], key = ref1[0], idx = ref1[1];
        text = as_text(data[key]);
        width = S.widths[idx];
        align = S.alignments[idx];
        ellipsis = S.ellipsis;
        R.push(to_width(text, width, {
          align: align,
          ellipsis: ellipsis
        }));
      }
      return S.box.left + (R.join(S.box.center)) + S.box.right;
    };
  })(this);

  $as_row = function(S) {
    return $(function(event, send) {
      var data, mark, row;
      mark = event[0], data = event[1];
      row = as_row(S, data, S.keys);
      if (mark === 'data') {
        return send(['table', row]);
      }
      return send(event);
    });
  };

  get_divider = function(S, position) {
    var R, center, column, count, i, idx, last_idx, left, len, ref1, right, width;
    switch (position) {
      case 'top':
        left = S.box.lt;
        center = S.box.ct;
        right = S.box.rt;
        break;
      case 'heading':
        left = S.box.lm;
        center = S.box.cm;
        right = S.box.rm;
        break;
      case 'mid':
        left = S.box.lm;
        center = S.box.cm;
        right = S.box.rm;
        break;
      case 'bottom':
        left = S.box.lb;
        center = S.box.cb;
        right = S.box.rb;
        break;
      default:
        throw new Error("unknown position " + (rpr(position)));
    }
    last_idx = S.widths.length - 1;
    R = [];

    /* TAINT simplified calculation; assumes single-width glyphs and symmetric padding etc. */
    ref1 = S.widths;
    for (idx = i = 0, len = ref1.length; i < len; idx = ++i) {
      width = ref1[idx];
      column = [];
      if (idx === 0) {
        column.push(left);
        count = (S.box.left_width - 1) + width + ((S.box.center_width - 1) / 2);
      } else if (idx === last_idx) {
        column.push(center);
        count = ((S.box.center_width - 1) / 2) + width + (S.box.right_width - 1);
      } else {
        column.push(center);
        count = ((S.box.center_width - 1) / 2) + width + ((S.box.center_width - 1) / 2);
      }
      column.push(S.box.hs.repeat(count));
      if (idx === last_idx) {
        column.push(right);
      }
      R.push(column.join(''));
    }
    return R.join('');
  };

  $dividers = function(S) {
    var $bottom, $mid, $top;
    $top = function() {
      return $('first', function(event, send) {
        var ref1;
        send(['table', get_divider(S, 'top')]);
        if ((ref1 = S.headings) !== null && ref1 !== false) {
          send(['table', as_row(S, S.headings)]);
          send(['table', get_divider(S, 'heading')]);
        }
        return send(event);
      });
    };
    $mid = function() {
      return $(function(event) {});
    };
    $bottom = function() {
      return $('last', function(event, send) {
        send(event);
        return send(['table', get_divider(S, 'bottom')]);
      });
    };
    return D.new_stream({
      pipeline: [$top(), $mid(), $bottom()]
    });
  };

  $cleanup = function(S) {
    return $(function(event, send) {
      var data, mark;
      mark = event[0], data = event[1];
      if (mark === 'table') {
        send(data);
      }
      return null;
    });
  };

  boxes = {
    plain: {
      lt: '┌',
      ct: '┬',
      rt: '┐',
      lm: '├',
      cm: '┼',
      rm: '┤',
      lb: '└',
      cb: '┴',
      rb: '┘',
      vs: '│',
      hs: '─'
    },
    round: {
      lt: '╭',
      ct: '┬',
      rt: '╮',
      lm: '├',
      cm: '┼',
      rm: '┤',
      lb: '╰',
      cb: '┴',
      rb: '╯',
      vs: '│',
      hs: '─'
    }
  };

  $as_event = function(S) {
    return $(function(data, send) {
      return send(['data', data]);
    });
  };

  as_text = function(x) {
    if (CND.isa_text(x)) {
      return x;
    } else {
      return rpr(x);
    }
  };

  copy = function(x) {
    if (CND.isa_list(x)) {
      return Object.assign([], x);
    }
    if (CND.isa_pod(x)) {
      return Object.assign({}, x);
    }
    return x;
  };

  (function(self) {
    var name, results, value;
    D = require('./main');
    results = [];
    for (name in self) {
      value = self[name];
      results.push(D[name] = value);
    }
    return results;
  })(this);

}).call(this);

//# sourceMappingURL=plugin-tabulate.js.map