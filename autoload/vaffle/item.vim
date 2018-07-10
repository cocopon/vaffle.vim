let s:save_cpo = &cpoptions
set cpoptions&vim


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


function! vaffle#item#get_cursor_items(env, mode) abort
  let items = a:env.items
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


let &cpoptions = s:save_cpo
