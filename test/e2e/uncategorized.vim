let s:suite = themis#suite('vaffle_e2e_uncategorized')
let s:assert = themis#helper('assert')
let s:cwd = getcwd()


function! s:suite.before_each() abort
  %bwipeout!
  execute printf('cd %s', fnameescape(s:cwd))
endfunction


function! s:suite.test_double_vaffle() abort
  Vaffle test/e2e/files
  let prev_dir = b:vaffle.dir
  Vaffle

  call s:assert.equals(
        \ prev_dir,
        \ b:vaffle.dir,
        \ ':Vaffle on Vaffle buffer should not change working directory')
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
