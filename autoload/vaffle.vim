let s:save_cpo = &cpoptions
set cpoptions&vim


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


function! s:get_cursor_items(env, mode) abort
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


function! s:get_selected_items(env) abort
  let items = a:env.items
  let selected_items = filter(
        \ copy(items),
        \ 'v:val.selected')
  if !empty(selected_items)
    return selected_items
  endif

  return s:get_cursor_items(a:env, 'n')
endfunction


function! vaffle#init(...) abort
  let bufnr = bufnr('%')
  let is_vaffle_buffer = vaffle#buffer#is_for_vaffle(bufnr)

  let path = get(a:000, 0, '')
  let extracted_path = vaffle#buffer#extract_path_from_bufname(path)
  if !empty(extracted_path)
    let path = extracted_path
  endif
  if empty(path)
    let path = getcwd()
  endif

  let bufname = bufname('%')
  if !is_vaffle_buffer && !isdirectory(bufname)
    " Open new directory buffer and overwrite it
    " (will be initialized by vaffle#event#on_bufenter)
    execute printf('edit %s', fnameescape(path))
    return
  endif

  try
    call vaffle#buffer#init(path)
    call vaffle#window#init()
  catch /:E37:/
    call vaffle#util#echo_error(
          \ 'E37: No write since last change')
    return
  endtry
endfunction


function! vaffle#refresh() abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let cursor_items = s:get_cursor_items(env, 'n')
  if !empty(cursor_items)
    call vaffle#buffer#save_cursor(cursor_items[0])
  endif

  let new_env = vaffle#env#create(env.dir)
  call vaffle#env#inherit(new_env, env)
  let new_env.items = vaffle#env#create_items(new_env)
  call vaffle#buffer#set_env(new_env)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#open_current(open_mode) abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let item = get(
        \ s:get_cursor_items(env, 'n'),
        \ 0,
        \ {})
  if empty(item)
    return
  endif

  call vaffle#buffer#save_cursor(item)

  call vaffle#file#open([item], a:open_mode)
endfunction


function! vaffle#open_selected(open_mode) abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let items = s:get_selected_items(env)
  if empty(items)
    return
  endif

  call vaffle#buffer#save_cursor(items[0])

  call vaffle#file#open(items, a:open_mode)
endfunction


function! vaffle#open(path) abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let env_dir = env.dir

  let cursor_items = s:get_cursor_items(env, 'n')
  if !empty(cursor_items)
    call vaffle#buffer#save_cursor(cursor_items[0])
  endif

  let new_dir = isdirectory(expand(a:path)) ?
        \ expand(a:path) :
        \ fnamemodify(expand(a:path), ':h')
  let new_item = vaffle#item#from_path(new_dir)
  call vaffle#file#open([new_item], '')

  " Move cursor to previous current directory
  let prev_dir_item =vaffle#item#from_path(env_dir)
  call vaffle#buffer#save_cursor(prev_dir_item)
  call vaffle#buffer#restore_cursor()
endfunction


function! vaffle#open_parent() abort
  let env = vaffle#buffer#get_env()
  let parent_dir = fnameescape(fnamemodify(env.dir, ':h'))
  call vaffle#open(parent_dir)
endfunction


function! vaffle#toggle_current(mode) abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let items = s:get_cursor_items(env, a:mode)
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

  let items = vaffle#buffer#get_env().items
  if empty(items)
    return
  endif

  call vaffle#set_selected_all(
        \ !items[0].selected)
endfunction


function! vaffle#set_selected_all(selected) abort
  call s:keep_buffer_singularity()

  for item in vaffle#buffer#get_env().items
    let item.selected = a:selected
  endfor

  call vaffle#buffer#redraw()
endfunction


function! vaffle#quit() abort
  call s:keep_buffer_singularity()

  " Try restoring previous buffer
  let bufnr = vaffle#window#get_env().non_vaffle_bufnr
  if bufexists(bufnr)
    execute printf('buffer! %d', bufnr)
    return
  endif

  enew
endfunction


function! vaffle#delete_selected() abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let items = s:get_selected_items(env)
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

  call vaffle#file#delete(items)
  call vaffle#refresh()
endfunction


function! vaffle#move_selected() abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let items = s:get_selected_items(env)
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
        \ vaffle#buffer#get_env(),
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
        \ vaffle#buffer#get_env(),
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
        \ vaffle#buffer#get_env(),
        \ name)
endfunction


function! vaffle#rename_selected() abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let items = s:get_selected_items(env)
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
          \ vaffle#buffer#get_env(),
          \ items, [new_basename])
    call vaffle#refresh()
    return
  endif

  call vaffle#rename_buffer#new(items)
endfunction


function! vaffle#toggle_hidden() abort
  call s:keep_buffer_singularity()

  let env = vaffle#buffer#get_env()
  let env.shows_hidden_files = !env.shows_hidden_files
  call vaffle#buffer#set_env(env)

  let item = get(
        \ s:get_cursor_items(env, 'n'),
        \ 0,
        \ {})
  if !empty(item)
    call vaffle#buffer#save_cursor(item)
  endif

  let env = vaffle#buffer#get_env()
  let env.items = vaffle#env#create_items(env)
  call vaffle#buffer#set_env(env)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#fill_cmdline() abort
  let env = vaffle#buffer#get_env()

  let items = s:get_selected_items(env)
  if empty(items)
    return
  endif

  let paths = map(items, 'fnameescape(v:val.path)')

  let cmdline =printf(
        \ ": %s\<Home>",
        \ join(paths, ' '))
  call feedkeys(cmdline)
endfunction


function! vaffle#chdir(path) abort
  call s:keep_buffer_singularity()

  try
    execute printf('lcd %s', fnameescape(a:path))
  catch /:E472:/
    " E472: Command failed
    " Permission denied, etc.
    call vaffle#util#echo_error(
          \ printf('Changing directory failed: ''%s''', a:path))
  endtry
endfunction


function! vaffle#chdir_here() abort
  let env = vaffle#buffer#get_env()
  call vaffle#chdir(env.dir)
endfunction


let &cpoptions = s:save_cpo
