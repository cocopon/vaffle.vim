let s:suite = themis#suite('vaffle#util')
let s:assert = themis#helper('assert')


function! s:get_listed_buffers() abort
  return filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
endfunction


function! s:suite.test_vaffle_init() abort
  e test/dummy/foo.txt
  e test/dummy/bar.txt
  Vaffle

  call s:assert.equals(
        \ len(s:get_listed_buffers()),
        \ 2,
        \ ':Vaffle should not unlist current buffer')
endfunction
