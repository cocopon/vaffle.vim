let s:suite = themis#suite('vaffle_e2e_duplication')
let s:assert = themis#helper('assert')


function! s:suite.before_each() abort
  %bwipeout!
endfunction


function! s:suite.test_duplicate_and_select() abort
  Vaffle test/e2e/files/duplication
  " Show hidden files
  normal .
  " Split the buffer
  execute "normal \<C-w>v"
  " Select the last item
  execute "normal G\<Space>"

  call s:assert.equals(
        \ len(b:vaffle.items),
        \ 2,
        \ 'Duplicated Vaffle also should show hidden files')
  call s:assert.equals(
        \ b:vaffle.items[1].selected,
        \ 1,
        \ 'Duplicated Vaffle should select correct file')
endfunction


function! s:suite.test_duplicate_and_select_hidden() abort
  Vaffle test/e2e/files/duplication
  " Show hidden files
  normal .
  " Split the buffer
  execute "normal \<C-w>v"
  " Select the first item
  execute "normal gg\<Space>"

  call s:assert.equals(
        \ b:vaffle.items[0].selected,
        \ 1,
        \ 'Duplicated Vaffle should select correct hidden file')
endfunction


function! s:suite.test_duplicate_and_quit() abort
  Vaffle test/e2e/files/duplication

  " Split the buffer
  execute "normal \<C-w>v"
  " Quit
  normal q

  call s:assert.equals(
        \ bufname('%'),
        \ '',
        \ 'Duplicated Vaffle should be closed')
  call s:assert.equals(
        \ &filetype,
        \ '',
        \ 'Duplicated Vaffle should be closed')

  " Focus another buffer
  execute "normal \<C-w>w"
  " Quit another buffer
  normal q

  call s:assert.equals(
        \ bufname('%'),
        \ '',
        \ 'Duplicated Vaffle should be closed')
  call s:assert.equals(
        \ &filetype,
        \ '',
        \ 'Duplicated Vaffle should be closed')
endfunction
