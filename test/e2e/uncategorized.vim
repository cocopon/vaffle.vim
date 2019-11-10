let s:suite = themis#suite('vaffle_e2e_uncategorized')
let s:assert = themis#helper('assert')


function! s:get_listed_buffers() abort
  return filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
endfunction


function! s:suite.test_init_unlist() abort
  e test/e2e/files/init_unlist/foo.txt
  e test/e2e/files/init_unlist/bar.txt
  Vaffle

  call s:assert.equals(
        \ len(s:get_listed_buffers()),
        \ 2,
        \ ':Vaffle should not unlist current buffer')
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
