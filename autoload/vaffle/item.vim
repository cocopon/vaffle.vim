" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#item#create(path) abort
  let is_dir = isdirectory(a:path)

  let item = {}
  let item.index = -1
  let item.path = vaffle#util#normalize_path(a:path)
  let item.is_dir = is_dir
  let item.selected = 0
  let item.basename = vaffle#util#get_last_component(a:path, is_dir)

  return item
endfunction


let &cpo = s:save_cpo
