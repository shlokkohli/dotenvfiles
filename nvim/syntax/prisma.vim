" Basic Prisma schema highlighting.
" This keeps schema.prisma readable even when Tree-sitter isn't available.

if exists('b:current_syntax')
  finish
endif

syntax case match

syntax keyword prismaTodo contained TODO FIXME NOTE XXX

syntax region prismaComment start='/\*' end='\*/' contains=prismaTodo,@Spell
syntax match prismaComment '//.*$' contains=prismaTodo,@Spell

syntax region prismaString start=+"+ skip=+\\\\\|\\"+ end=+"+
syntax match prismaNumber /\v<\d+(\.\d+)?>/
syntax keyword prismaBoolean true false

syntax match prismaBlock /^\s*\%(datasource\|generator\|model\|enum\|type\|view\)\>/
syntax match prismaBlockName /^\s*\%(datasource\|generator\|model\|enum\|type\|view\)\s\+\zs\h\w*/
syntax match prismaFieldType /^\s*\h\w*\s\+\zs\h\w*\ze\%(\s\|?\|\[\|@\|$\)/

syntax keyword prismaBuiltinType String Boolean Int BigInt Float Decimal DateTime Json Bytes Unsupported

syntax match prismaNativeType /@db\.\h\w*/
syntax match prismaAttribute /@@\=\h\w*/
syntax match prismaFunction /\<\h\w*\ze(/

syntax match prismaOperator /[][(){}.,:=?]/

highlight default link prismaTodo Todo
highlight default link prismaComment Comment
highlight default link prismaString String
highlight default link prismaNumber Number
highlight default link prismaBoolean Boolean
highlight default link prismaBlock Keyword
highlight default link prismaBlockName Type
highlight default link prismaFieldType Type
highlight default link prismaBuiltinType Type
highlight default link prismaNativeType Type
highlight default link prismaAttribute Macro
highlight default link prismaFunction Function
highlight default link prismaOperator Delimiter

let b:current_syntax = 'prisma'
