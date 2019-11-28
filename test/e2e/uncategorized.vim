let s:suite = themis#suite('vaffle_e2e_uncategorized')
let s:assert = themis#helper('assert')


function! s:suite.before_each() abort
  %bwipeout!
endfunction


function! s:get_listed_buffers() abort
  return filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
endfunction


" https://github.com/cocopon/vaffle.vim/issues/31
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
