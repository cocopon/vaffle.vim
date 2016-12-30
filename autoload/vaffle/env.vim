" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! vaffle#env#set_up(path) abort
  let w:vaffle = get(w:, 'vaffle', {})

  let w:vaffle.restored = 0
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

  call vaffle#env#set_up_items()
endfunction


function! vaffle#env#set_up_items() abort
  let paths = vaffle#compat#glob_list(w:vaffle.dir . '/*')
  if w:vaffle.shows_hidden_files
    let hidden_paths = vaffle#compat#glob_list(w:vaffle.dir . '/.*')
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''/\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let w:vaffle.items =  map(
        \ copy(paths),
        \ 'vaffle#item#create(v:val)')
  call sort(w:vaffle.items, 'vaffle#sorter#default#compare')

  let index = 0
  for item in w:vaffle.items
    let item.index = index
    let index += 1
  endfor

  let b:vaffle = w:vaffle
endfunction


function! vaffle#env#get() abort
  let w:vaffle = get(w:, 'vaffle', get(b:, 'vaffle', {}))
  return w:vaffle
endfunction


function! vaffle#env#set(key, value) abort
  let w:vaffle = get(w:, 'vaffle', get(b:, 'vaffle', {}))
  let w:vaffle[a:key] = a:value
endfunction


function! vaffle#env#save_cursor(item) abort
  let cursor_paths = vaffle#env#get().cursor_paths
  let cursor_paths[w:vaffle.dir] = a:item.path
  call vaffle#env#set('cursor_paths', cursor_paths)
endfunction


function! vaffle#env#restore_cursor() abort
  let cursor_paths = vaffle#env#get().cursor_paths
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


function! vaffle#env#should_restore() abort
  if &filetype ==? 'vaffle'
    " Active Vaffle buffer
    return 0
  endif

  if !exists('w:vaffle')
    " Buffer not for Vaffle
    return 0
  endif

  if !exists('w:vaffle.restored')
        \ || w:vaffle.restored
    " Already restored
    return 0
  endif

  return 1
endfunction


let &cpo = s:save_cpo
