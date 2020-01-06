let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#sorter#default#compare(r1, r2) abort
  if a:r1.is_dir != a:r2.is_dir
    " Show directory in first
    return a:r1.is_dir ? -1 : +1
  endif

  return char2nr(a:r1.basename) - char2nr(a:r2.basename)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
