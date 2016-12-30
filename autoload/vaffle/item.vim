" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#item#get_cursor_items(mode) abort
  let items = vaffle#env#get().items
  if empty(items)
    return []
  endif

  let in_visual_mode = (a:mode ==? 'v')
  let indexes = in_visual_mode
        \ ? range(line('''<') - 1, line('''>') - 1)
        \ : [line('.') - 1]
  return map(
        \ copy(indexes),
        \ 'items[v:val]')
endfunction


function! vaffle#item#get_selected_items() abort
  let items = vaffle#env#get().items
  let selected_items = filter(
        \ copy(items),
        \ 'v:val.selected')
  if !empty(selected_items)
    return selected_items
  endif

  return vaffle#item#get_cursor_items('n')
endfunction


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
