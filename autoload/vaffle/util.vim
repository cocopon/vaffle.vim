" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#util#normalize_path(path) abort
  if a:path ==? '/'
    return '/'
  endif

  let result = resolve(a:path)

  " Remove trailing path separator
  return (match(result, '/$') >= 0)
        \ ? fnamemodify(result, ':h')
        \ : result
endfunction


function! vaffle#util#get_last_component(path, is_dir) abort
  return a:is_dir
        \ ? fnamemodify(a:path, ':t')
        \ : fnamemodify(a:path, ':p:t')
endfunction


function! vaffle#util#echo_error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction


let &cpo = s:save_cpo
