" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#sorter#default#compare(r1, r2) abort
  if a:r1.is_dir != a:r2.is_dir
    " Show directory in first
    return a:r1.is_dir ? -1 : +1
  endif

  return char2nr(a:r1.basename) - char2nr(a:r2.basename)
endfunction


let &cpo = s:save_cpo
