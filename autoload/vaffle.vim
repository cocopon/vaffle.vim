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


function! s:lnum_to_item_index(lnum) abort
  return a:lnum - 1
endfunction


function! s:get_cursor_items(filer, mode) abort
  let items = a:filer.items
  if empty(items)
    return []
  endif

  let in_visual_mode = (a:mode ==? 'v')
  let lnums = in_visual_mode
        \ ? range(line('''<'), line('''>'))
        \ : [line('.')]
  return map(
        \ copy(lnums),
        \ 'items[s:lnum_to_item_index(v:val)]')
endfunction


function! s:get_selected_items(filer) abort
  let items = a:filer.items
  let selected_items = filter(
        \ copy(items),
        \ 'v:val.selected')
  if !empty(selected_items)
    return selected_items
  endif

  return s:get_cursor_items(a:filer, 'n')
endfunction


function! s:should_wipe_out(bufnr) abort
  if !bufexists(a:bufnr)
    return 0
  endif

  return vaffle#buffer#is_for_vaffle(a:bufnr)
        \ && !buflisted(a:bufnr)
        \ && !bufloaded(a:bufnr)
endfunction


function! s:clean_up_outdated_buffers() abort
  let all_bufnrs = range(1, bufnr('$'))
  let outdated_bufnrs = filter(
        \ all_bufnrs,
        \ 's:should_wipe_out(v:val)')
  for bufnr in outdated_bufnrs
    execute printf('silent bwipeout %d', bufnr)
  endfor
endfunction


function! vaffle#init(...) abort
  let path = get(a:000, 0, '')
  if empty(path)
    let path = expand('%:p')
  endif

  let extracted_path = vaffle#buffer#extract_path_from_bufname(path)
  let path = !empty(extracted_path)
        \ ? extracted_path
        \ : path 

  let path = fnamemodify(path, ':p')

  if !isdirectory(path)
    " Open new directory buffer and overwrite it
    " (will be initialized by vaffle#event#on_bufenter)
    let dir = fnamemodify(path, ':h')
    execute printf('edit %s', fnameescape(dir))

    call vaffle#buffer#move_cursor_to_path(
          \ fnamemodify(path, ':p'))
    return
  endif

  try
    call s:clean_up_outdated_buffers()

    " If current buffer is for existing file, create new buffer before init
    " to avoid overwriting the buffer
    let should_new_buffer = filereadable(expand('%:p'))
    if should_new_buffer
      enew
    endif

    let filer = vaffle#filer#create(path)
    call vaffle#filer#inherit(filer, vaffle#buffer#get_filer())
    let filer.items = vaffle#file#create_items_from_dir(
          \ filer.dir,
          \ filer.shows_hidden_files)

    call vaffle#buffer#init(filer)
    call vaffle#window#init()
  catch /:E37:/
    call vaffle#util#echo_error(
          \ 'E37: No write since last change')
    return
  endtry
endfunction


function! vaffle#refresh() abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let cursor_items = s:get_cursor_items(filer, 'n')
  if !empty(cursor_items)
    call vaffle#buffer#save_cursor(cursor_items[0])
  endif

  let new_filer = vaffle#filer#create(filer.dir)
  call vaffle#filer#inherit(new_filer, filer)
  let new_filer.items = vaffle#file#create_items_from_dir(
        \ new_filer.dir,
        \ new_filer.shows_hidden_files)
  call vaffle#buffer#set_filer(new_filer)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#open_current(open_mode) abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let item = get(
        \ s:get_cursor_items(filer, 'n'),
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

  let filer = vaffle#buffer#get_filer()
  let items = s:get_selected_items(filer)
  if empty(items)
    return
  endif

  call vaffle#buffer#save_cursor(items[0])

  call vaffle#file#open(items, a:open_mode)
endfunction


function! vaffle#open(path) abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let filer_dir = filer.dir

  let cursor_items = s:get_cursor_items(filer, 'n')
  if !empty(cursor_items)
    call vaffle#buffer#save_cursor(cursor_items[0])
  endif

  let new_dir = isdirectory(expand(a:path)) ?
        \ expand(a:path) :
        \ fnamemodify(expand(a:path), ':h')
  let new_item = vaffle#item#from_path(new_dir)
  call vaffle#file#open([new_item], '')

  " Move cursor to previous current directory
  let prev_dir_item =vaffle#item#from_path(filer_dir)
  call vaffle#buffer#save_cursor(prev_dir_item)
  call vaffle#buffer#restore_cursor()
endfunction


function! vaffle#open_parent() abort
  let filer = vaffle#buffer#get_filer()
  let parent_dir = fnameescape(fnamemodify(filer.dir, ':h'))
  call vaffle#open(parent_dir)
endfunction


function! vaffle#toggle_current(mode) abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let items = s:get_cursor_items(filer, a:mode)
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

  let items = vaffle#buffer#get_filer().items
  if empty(items)
    return
  endif

  call vaffle#set_selected_all(
        \ !items[0].selected)
endfunction


function! vaffle#set_selected_all(selected) abort
  call s:keep_buffer_singularity()

  for item in vaffle#buffer#get_filer().items
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

  let items = s:get_selected_items(
        \ vaffle#buffer#get_filer())
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

  let lnum = line('.')

  call vaffle#file#delete(items)
  call vaffle#refresh()

  " Restore cursor position
  call vaffle#buffer#move_cursor_to_lnum(lnum)
endfunction


function! vaffle#move_selected() abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let items = s:get_selected_items(filer)
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
        \ vaffle#buffer#get_filer(),
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
        \ vaffle#buffer#get_filer(),
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
        \ vaffle#buffer#get_filer(),
        \ name)
endfunction


function! vaffle#rename_selected() abort
  call s:keep_buffer_singularity()

  let items = s:get_selected_items(
        \ vaffle#buffer#get_filer())
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

    let renamed_paths = vaffle#file#rename(
          \ vaffle#buffer#get_filer(),
          \ items, [new_basename])

    call vaffle#refresh()

    if !empty(renamed_paths[0])
      call vaffle#buffer#move_cursor_to_path(renamed_paths[0])
    endif
    return
  endif

  call vaffle#rename_buffer#new(items)
endfunction


function! vaffle#toggle_hidden() abort
  call s:keep_buffer_singularity()

  let filer = vaffle#buffer#get_filer()
  let filer.shows_hidden_files = !filer.shows_hidden_files
  call vaffle#buffer#set_filer(filer)

  let item = get(
        \ s:get_cursor_items(filer, 'n'),
        \ 0,
        \ {})
  if !empty(item)
    call vaffle#buffer#save_cursor(item)
  endif

  let filer = vaffle#buffer#get_filer()
  let filer.items = vaffle#file#create_items_from_dir(
        \ filer.dir,
        \ filer.shows_hidden_files)
  call vaffle#buffer#set_filer(filer)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#fill_cmdline() abort
  let filer = vaffle#buffer#get_filer()

  let items = s:get_selected_items(filer)
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
  let filer = vaffle#buffer#get_filer()
  call vaffle#chdir(filer.dir)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
