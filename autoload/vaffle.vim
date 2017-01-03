" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! s:keep_buffer_singularity() abort
  let related_win_ids = vaffle#compat#win_findbuf(bufnr('%'))
  if len(related_win_ids) <= 1
    return 1
  endif

  " Detected multiple windows for single buffer:
  " Duplicate the buffer to avoid unwanted sync between different windows
  call vaffle#buffer#duplicate()

  return 1
endfunction


function! vaffle#init(...) abort
  let path = (a:0 == 0)
        \ ? getcwd()
        \ : a:1
  if !isdirectory(path)
    call vaffle#util#echo_error(
          \ printf('Not a directory: ''%s''', path))
    return
  endif

  if &filetype ==? 'vaffle'
    call vaffle#buffer#reuse(path)
    return
  endif

  if !isdirectory(bufname('%'))
    " Create new buffer for non-directory buffer
    let g:vaffle_creating_vaffle_buffer = 1
    enew
    unlet g:vaffle_creating_vaffle_buffer
  endif

  try
    call vaffle#buffer#init(path)
  catch /:E37:/
    call vaffle#util#echo_error(
          \ 'E37: No write since last change')
    return
  endtry
endfunction


function! vaffle#refresh() abort
  call s:keep_buffer_singularity()

  let cursor_items = vaffle#item#get_cursor_items('n')
  if !empty(cursor_items)
    call vaffle#env#save_cursor(cursor_items[0])
  endif

  let cwd = vaffle#env#get().dir
  call vaffle#env#set_up(cwd)
  call vaffle#buffer#redraw()
endfunction


function! vaffle#open_current() abort
  call s:keep_buffer_singularity()

  let item = get(
        \ vaffle#item#get_cursor_items('n'),
        \ 0,
        \ {})
  if empty(item)
    return
  endif

  call vaffle#env#save_cursor(item)

  call vaffle#file#open(
        \ vaffle#env#get(),
        \ [item])
endfunction


function! vaffle#open_selected() abort
  call s:keep_buffer_singularity()

  let items = vaffle#item#get_selected_items()
  if empty(items)
    return
  endif

  call vaffle#env#save_cursor(items[0])

  call vaffle#file#open(
        \ vaffle#env#get(),
        \ items)
endfunction


function! vaffle#open_parent() abort
  call s:keep_buffer_singularity()

  let env = vaffle#env#get()
  let parent_dir = fnamemodify(env.dir, ':h')

  let cursor_items = vaffle#item#get_cursor_items('n')
  if !empty(cursor_items)
    call vaffle#env#save_cursor(cursor_items[0])
  endif

  let item = vaffle#item#create(parent_dir)
  call vaffle#file#open(env, [item])
endfunction


function! vaffle#toggle_current(mode) abort
  call s:keep_buffer_singularity()

  let items = vaffle#item#get_cursor_items(a:mode)
  if empty(items)
    return
  endif

  if len(items) == 1
    let item = items[0]
    let item.selected = item.selected ? 0 : 1

    call vaffle#buffer#redraw_item(item)

    " Move cursor to next item
    normal! j0

    return
  endif

  let selected = items[0].selected ? 0 : 1
  for item in items
    let item.selected = selected
    call vaffle#buffer#redraw_item(item)
  endfor
endfunction


function! vaffle#toggle_all() abort
  call s:keep_buffer_singularity()

  let items = vaffle#env#get().items
  if empty(items)
    return
  endif

  call vaffle#set_selected_all(
        \ !items[0].selected)
endfunction


function! vaffle#set_selected_all(selected) abort
  call s:keep_buffer_singularity()

  for item in vaffle#env#get().items
    let item.selected = a:selected
  endfor

  call vaffle#buffer#redraw()
endfunction


function! vaffle#quit() abort
  call s:keep_buffer_singularity()

  " Try restoring previous buffer
  let bufnr = vaffle#env#get().non_vaffle_bufnr
  if bufexists(bufnr)
    execute printf('buffer! %d', bufnr)
    return
  endif

  " Avoid quitting the last window
  let tabinfo = vaffle#compat#gettabinfo(tabpagenr())
  if !empty(tabinfo)
    if len(tabinfo[0].windows) <= 1
      " This is the last window: create empty buffer
      enew
      return
    endif
  endif

  quit
endfunction


function! vaffle#delete_selected() abort
  call s:keep_buffer_singularity()

  let items = vaffle#item#get_selected_items()
  if empty(items)
    return
  endif

  let message = (len(items) == 1)
        \ ? printf('Delete ''%s'' (y/N)? ', items[0].basename)
        \ : printf('Delete %d selected files (y/N)? ', len(items))
  let yn = input(message)
  echo "\n"
  if empty(yn) || yn ==? 'n'
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#delete(
        \ vaffle#env#get(),
        \ items)
  call vaffle#refresh()
endfunction


function! vaffle#move_selected() abort
  call s:keep_buffer_singularity()

  let items = vaffle#item#get_selected_items()
  if empty(items)
    return
  endif

  let message = (len(items) == 1)
        \ ? printf('Move ''%s'' to: ', items[0].basename)
        \ : printf('Move %d selected files to: ', len(items))
  let dst_name = input(message, '', 'dir')
  echo "\n"
  if empty(dst_name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#move(
        \ vaffle#env#get(),
        \ items, dst_name)
  call vaffle#refresh()
endfunction


function! vaffle#mkdir() abort
  call s:keep_buffer_singularity()

  let name = input('New directory name: ')
  echo "\n"
  if empty(name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#mkdir(
        \ vaffle#env#get(),
        \ name)
  call vaffle#refresh()
endfunction


function! vaffle#new_file() abort
  call s:keep_buffer_singularity()

  let name = input('New file name: ')
  echo "\n"
  if empty(name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#edit(
        \ vaffle#env#get(),
        \ name)
endfunction


function! vaffle#rename_selected() abort
  call s:keep_buffer_singularity()

  let items = vaffle#item#get_selected_items()
  if empty(items)
    return
  endif

  if len(items) == 1
    let def_name = vaffle#util#get_last_component(
          \ items[0].path, items[0].is_dir)
    let new_basename = input('New file name: ', def_name)
    echo "\n"
    if empty(new_basename)
      echo 'Cancelled.'
      return
    endif

    call vaffle#file#rename(
          \ vaffle#env#get(),
          \ items, [new_basename])
    call vaffle#refresh()
    return
  endif

  call vaffle#rename_buffer#new(items)
endfunction


function! vaffle#toggle_hidden() abort
  call s:keep_buffer_singularity()

  call vaffle#env#set(
        \ 'shows_hidden_files',
        \ !vaffle#env#get().shows_hidden_files)

  let item = get(
        \ vaffle#item#get_cursor_items('n'),
        \ 0,
        \ {})
  if !empty(item)
    call vaffle#env#save_cursor(item)
  endif

  call vaffle#env#set_up_items()
  call vaffle#buffer#redraw()
endfunction


let &cpo = s:save_cpo
