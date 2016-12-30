" Author:  cocopon <cocopon@me.com>
" License: MIT License


if exists('b:current_syntax')
  finish
endif


syn match vaffleDirectory '^  .\+/$'
syn match vaffleHidden '^  \..\+$'
syn match vaffleSelected '^* .\+$'

hi! def link vaffleDirectory Directory
hi! def link vaffleHidden Comment
hi! def link vaffleSelected Special


let b:current_syntax = 'vaffle'
