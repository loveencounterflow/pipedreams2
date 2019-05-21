


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'MKTS-PARSER/TYPES'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
jr                        = JSON.stringify
Intertype                 = ( require 'intertype' ).Intertype
intertype                 = new Intertype module.exports

# #-----------------------------------------------------------------------------------------------------------
# @declare 'mirage_main_row',
#   tests:
#     "? is a object":                          ( x ) -> @isa.object          x
#     "? has key 'key'":                        ( x ) -> @has_key             x, 'key'
#     "? has key 'vlnr_txt'":                   ( x ) -> @has_key             x, 'vlnr_txt'
#     "? has key 'value'":                      ( x ) -> @has_key             x, 'value'
#     "?.key is a nonempty text":               ( x ) -> @isa.nonempty_text   x.key
#     "?.vlnr_txt is a nonempty text":          ( x ) -> @isa.nonempty_text   x.vlnr_txt
#     "?.vlnr_txt starts, ends with '[]'":      ( x ) -> ( x.vlnr_txt.match /^\[.*\]$/ )?
#     "?.vlnr_txt is a JSON array of integers": ( x ) ->
#       # debug 'µ55589', x
#       ( @isa.list ( lst = JSON.parse x.vlnr_txt ) ) and \
#       ( lst.every ( xx ) => ( @isa.integer xx ) and ( @isa.positive xx ) )

# #-----------------------------------------------------------------------------------------------------------
# @declare 'true', ( x ) -> x is true
