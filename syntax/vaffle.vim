if exists('b:current_syntax')
  finish
endif

syn match vaffleDirectory '^  .\+/$'
syn match vaffleHidden '^  \..\+$'
syn match vaffleHiddenWithIcon '^  . \..\+$'
syn match vaffleSelected '^* .\+$'
syn match vaffleNoItems '^  (no items)$'
syn match vaffleHeader '^\S*:'

hi! def link vaffleDirectory Directory
hi! def link vaffleHidden Comment
hi! def link vaffleHiddenWithIcon Comment
hi! def link vaffleNoItems Comment
hi! def link vaffleSelected Special
hi! def link vaffleHeader Special

let b:current_syntax = 'vaffle'
