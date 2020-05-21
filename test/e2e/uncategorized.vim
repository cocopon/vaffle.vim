let s:suite = themis#suite('vaffle_e2e_uncategorized')
let s:assert = themis#helper('assert')
let s:cwd = getcwd()


function! s:suite.before_each() abort
  %bwipeout!
  execute printf('cd %s', fnameescape(s:cwd))
endfunction


function! s:suite.test_reinit_deleted_buffer() abort
  Vaffle test/e2e/files/duplication
  " Open item
  normal l
  " Then go back
  execute "normal \<C-o>"

  call s:assert.equals(
        \ &filetype,
        \ 'vaffle',
        \ 'Deleted Vaffle buffer should be re-initialized')
endfunction


function! s:suite.test_not_init_modified_buffer() abort
  call setline(1, 'foobar')
  Vaffle

  call s:assert.not_equals(
        \ &filetype,
        \ 'vaffle',
        \ 'Vaffle should not initialize modified buffer')
endfunction


function! s:suite.test_init_without_arguments() abort
  cd test/e2e/files
  e duplication/visible.txt
  Vaffle

  call s:assert.equals(
        \ fnamemodify(b:vaffle.dir, ':t'),
        \ 'files',
        \ 'Vaffle without arguments should open current working directory')
endfunction
