let s:suite = themis#suite('vaffle#util')
let s:assert = themis#helper('assert')


function! s:get_listed_buffers() abort
  return filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
endfunction


function! s:suite.test_vaffle_init_unlist() abort
  e test/files/init_unlist/foo.txt
  e test/files/init_unlist/bar.txt
  Vaffle

  call s:assert.equals(
        \ len(s:get_listed_buffers()),
        \ 2,
        \ ':Vaffle should not unlist current buffer')
endfunction


function! s:suite.test_vaffle_duplicate_and_select() abort
  Vaffle test/files/duplication
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


function! s:suite.test_vaffle_duplicate_and_select_hidden() abort
  Vaffle test/files/duplication
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


function! s:suite.test_vaffle_duplicate_and_quit() abort
  Vaffle test/files/duplication
  " Split the buffer
  execute "normal \<C-w>v"
  " Quit
  normal q

  call s:assert.equals(
        \ bufname('%'),
        \ '',
        \ 'Duplicated Vaffle should quit')
  call s:assert.equals(
        \ &filetype,
        \ '',
        \ 'Duplicated Vaffle should quit')
endfunction
