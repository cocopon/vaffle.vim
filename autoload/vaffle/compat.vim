" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#compat#glob_list(expr) abort
  if v:version < 703 ||
        \ (v:version == 703 && !has('patch465'))
    " {list} argument of glob() is available since patch 7.3.465
    " Outdated glob() returns multi-line string so split the result by "\n"
    return split(glob(a:expr), "\n")
  endif

  return glob(a:expr, 1, 1)
endfunction


function! vaffle#compat#win_findbuf(bufnr) abort
  if !exists('*win_findbuf')
    " win_findbuf() is available since patch 7.4.1558
    return []
  endif

  return win_findbuf(a:bufnr)
endfunction


function! vaffle#compat#win_getid() abort
  if !exists('*win_getid')
    " win_getid() is available since patch 7.4.1557
    return 0
  endif

  return win_getid()
endfunction


function! vaffle#compat#win_gotoid(expr) abort
  if !exists('*win_gotoid')
    " win_gotoid() is available since patch 7.4.1557
    return 0
  endif

  return win_gotoid(a:expr)
endfunction


let &cpoptions = s:save_cpo
