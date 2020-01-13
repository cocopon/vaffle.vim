let s:suite = themis#suite('vaffle_e2e_uncategorized')
let s:assert = themis#helper('assert')
let s:cwd = getcwd()


function! s:suite.before_each() abort
  %bwipeout!
  execute printf('cd %s', fnameescape(s:cwd))
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


" https://github.com/cocopon/vaffle.vim/issues/38
function! s:suite.test_init_unlist_dir() abort
  lcd test/e2e/files/init_unlist
  Vaffle
  execute "normal /foo\<CR>l"
  Vaffle ./
  execute "normal /bar\<CR>l"
  call s:assert.equals(
        \ len(s:get_listed_buffers()),
        \ 2,
        \ ':Vaffle should not unlist current buffer with :Vaffle {dir}')
endfunction
