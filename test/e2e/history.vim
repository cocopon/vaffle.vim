let s:suite = themis#suite('vaffle_e2e_history')
let s:assert = themis#helper('assert')
let s:cwd = getcwd()


function! s:suite.before_each() abort
  %bwipeout!
  execute printf('cd %s', fnameescape(s:cwd))
endfunction



function! s:suite.test_keepalt() abort
  cd test/e2e/files
  " Open file
  e history/foo.txt

  Vaffle
  " Move to parent directory
  normal h

  call s:assert.equals(
        \ fnamemodify(bufname('#'), ':t'),
        \ 'foo.txt',
        \ 'Vaffle navigation should keep alternate file')
endfunction

function! s:suite.test_keepalt() abort
  cd test/e2e/files
  " Open file
  e history/alt.txt

  Vaffle history

  " edit another file via vaffle; alt.txt should remain the alternate
  call search('foo.txt')
  call vaffle#open_current('')

  call s:assert.equals(
        \ fnamemodify(bufname('#'), ':t'),
        \ 'alt.txt',
        \ 'Vaffle navigation should keep alternate file')
endfunction

function! s:suite.quit_goes_to_alt() abort
  cd test/e2e/files

  e history/alt.txt

  Vaffle

  normal q

  call s:assert.equals(
        \ fnamemodify(bufname('%'), ':t'),
        \ 'alt.txt',
        \ 'Vaffle quit should return to original file')
endfunction

function! s:suite.quit_goes_to_empty_buf() abort
  cd test/e2e/files

  " vaffle opens with no alternate file available
  Vaffle

  normal q

  call s:assert.equals(
        \ fnamemodify(bufname('%'), ':t'),
        \ '',
        \ 'Vaffle quit should open new, empty buf')
endfunction
