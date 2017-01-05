" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#env#create(path) abort
endfunction


function! vaffle#env#set_up(path) abort
  let w:vaffle = get(w:, 'vaffle', {})

  let w:vaffle.dir = vaffle#util#normalize_path(a:path)
  let w:vaffle.cursor_paths = get(
        \ w:vaffle,
        \ 'cursor_paths',
        \ {})

  let w:vaffle.non_vaffle_bufnr = get(
        \ w:vaffle,
        \ 'non_vaffle_bufnr',
        \ -1)
  if w:vaffle.non_vaffle_bufnr == bufnr('%')
    let w:vaffle.non_vaffle_bufnr = -1
  endif

  let w:vaffle.shows_hidden_files = get(
        \ w:vaffle,
        \ 'shows_hidden_files',
        \ g:vaffle_show_hidden_files)

  let w:vaffle.items = vaffle#env#create_items(w:vaffle)

  let b:vaffle = w:vaffle
endfunction


function! vaffle#env#create_items(env) abort
  let paths = vaffle#compat#glob_list(a:env.dir . '/*')
  if a:env.shows_hidden_files
    let hidden_paths = vaffle#compat#glob_list(a:env.dir . '/.*')
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''/\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let items =  map(
        \ copy(paths),
        \ 'vaffle#item#create(v:val)')
  call sort(items, 'vaffle#sorter#default#compare')

  let index = 0
  for item in items
    let item.index = index
    let index += 1
  endfor

  return items
endfunction


function! vaffle#env#set(key, value) abort
  let w:vaffle = get(w:, 'vaffle', get(b:, 'vaffle', {}))
  let w:vaffle[a:key] = a:value
endfunction


function! vaffle#env#save_cursor(item) abort
  let cursor_paths = vaffle#buffer#get_env().cursor_paths
  let cursor_paths[w:vaffle.dir] = a:item.path
  call vaffle#env#set('cursor_paths', cursor_paths)
endfunction


function! vaffle#env#restore_cursor() abort
  let cursor_paths = vaffle#buffer#get_env().cursor_paths
  let cursor_path = get(cursor_paths, w:vaffle.dir, '')
  if empty(cursor_path)
    return {}
  endif

  let items = filter(
        \ copy(w:vaffle.items),
        \ 'v:val.path ==# cursor_path')
  if empty(items)
    return {}
  endif

  return items[0]
endfunction


function! vaffle#env#restore_from_buffer() abort
  " Split buffer doesn't have `w:vaffle` so restore it from `b:vaffle`
  let w:vaffle = deepcopy(b:vaffle)
endfunction


let &cpo = s:save_cpo
