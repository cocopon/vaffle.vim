let s:suite = themis#suite('vaffle_e2e_jump')
let s:assert = themis#helper('assert')
let s:cwd = getcwd()


function! s:suite.before_each() abort
  %bwipeout!
  execute printf('cd %s', fnameescape(s:cwd))
endfunction


function! s:suite.test_back() abort
  e test/e2e/files/jump/foo.txt
  e test/e2e/files/jump/bar.txt
  Vaffle
  execute "normal \<C-o>"

  call s:assert.equals(
        \ expand('%:t'),
        \ 'bar.txt',
        \ '<C-o> on Vaffle should show previous buffer')

  execute "normal 1\<C-i>"
  call s:assert.equals(
        \ &filetype,
        \ 'vaffle',
        \ '<C-i> on previous buffer should show Vaffle again')
endfunction
