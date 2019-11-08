let s:suite = themis#suite('vaffle-ui')
let s:assert = themis#helper('assert')


function! s:get_listed_buffers() abort
  return filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
endfunction


function! s:suite.test_init_unlist() abort
  e test/files/init_unlist/foo.txt
  e test/files/init_unlist/bar.txt
  Vaffle

  call s:assert.equals(
        \ len(s:get_listed_buffers()),
        \ 2,
        \ ':Vaffle should not unlist current buffer')
endfunction
