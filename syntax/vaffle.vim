if exists('b:current_syntax')
  finish
endif


syn match vaffleDirectory '^  .\+/$'
syn match vaffleHidden '^  \..\+$'
syn match vaffleSelected '^* .\+$'
syn match vaffleNoItems '^  (no items)$'

hi! def link vaffleDirectory Directory
hi! def link vaffleHidden Comment
hi! def link vaffleNoItems Comment
hi! def link vaffleSelected Special


let b:current_syntax = 'vaffle'
