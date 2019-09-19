let s:save_cpo = &cpoptions
set cpoptions&vim


let s:open_mode_to_cmd_single_map = {
      \   '':       'edit',
      \   'tab':    'tabedit',
      \   'split':  get(g:, 'vaffle_open_selected_split_position', '') . ' split',
      \   'vsplit': get(g:, 'vaffle_open_selected_vsplit_position', '') . ' vsplit',
      \ }
let s:open_mode_to_cmd_multiple_map = {
      \   '':       'split',
      \   'tab':    'tabedit',
      \   'split':  get(g:, 'vaffle_open_selected_split_position', '') . ' split',
      \   'vsplit': get(g:, 'vaffle_open_selected_vsplit_position', '') . ' vsplit',
      \ }


function! s:open_single(item, open_mode) abort
  let path = a:item.path

  if isdirectory(path)
    if a:open_mode ==# 'tab'
      tabnew
    endif

    call vaffle#init(path)
    return
  endif

  let open_cmd = get(s:open_mode_to_cmd_single_map,
        \ a:open_mode,
        \ 'edit')
  execute printf('%s %s',
        \ open_cmd,
        \ fnameescape(a:item.path))
endfunction


function! s:open_multiple(items, open_mode) abort
  let open_cmd = get(s:open_mode_to_cmd_multiple_map,
        \ a:open_mode,
        \ 'split')

  for item in a:items
    execute printf('%s %s',
          \ open_cmd,
          \ fnameescape(item.path))
  endfor
endfunction


function! vaffle#file#create_items_from_dir(dir, includes_hidden_files) abort
  let escaped_dir = fnameescape(fnamemodify(a:dir, ':p'))
  let paths = vaffle#compat#glob_list(escaped_dir . '*')
  if a:includes_hidden_files
    let hidden_paths = vaffle#compat#glob_list(escaped_dir . '.*')
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let items =  map(
        \ copy(paths),
        \ 'vaffle#item#from_path(v:val)')
  call sort(items, 'vaffle#sorter#default#compare')

  let index = 0
  for item in items
    let item.index = index
    let index += 1
  endfor

  return items
endfunction


function! vaffle#file#open(items, open_mode) abort
  if len(a:items) == 1
    call s:open_single(a:items[0], a:open_mode)
  else
    call s:open_multiple(a:items, a:open_mode)
  endif
endfunction


function! vaffle#file#delete(items) abort
  for item in a:items
    let flag = g:vaffle_force_delete
          \ ? 'rf'
          \ : (item.is_dir ? 'd' : '')
    if delete(item.path, flag) < 0
      call vaffle#util#echo_error(
            \ printf('Cannot delete file: ''%s''', item.basename))
    else
      echo printf('Deleted file: ''%s''',
            \ item.basename)
    endif
  endfor
endfunction


function! vaffle#file#mkdir(filer, name) abort
  let path = vaffle#util#normalize_path(printf('%s/%s',
        \ a:filer.dir,
        \ a:name))

  if filereadable(path) || isdirectory(path)
    call vaffle#util#echo_error(
          \ printf('File already exists: ''%s''', a:name))
    return
  endif

  call mkdir(path, '')

  echo printf('Created new directory: ''%s''',
        \ a:name)
endfunction


function! vaffle#file#edit(filer, name) abort
  let path = vaffle#util#normalize_path(printf('%s/%s',
        \ a:filer.dir,
        \ a:name))
  execute printf('edit %s', fnameescape(path))
endfunction


function! vaffle#file#move(filer, items, dst_name) abort
  let dst_dir = vaffle#util#normalize_path(printf('%s/%s',
        \ a:filer.dir,
        \ a:dst_name))

  if !isdirectory(dst_dir)
    call vaffle#util#echo_error(
          \ printf('Destination is not a directory: ''%s''', dst_dir))
    return
  endif

  for item in a:items
    let basename = vaffle#util#get_last_component(
          \ item.path,
          \ item.is_dir)
    let dst_path = vaffle#util#normalize_path(printf('%s/%s',
          \ dst_dir,
          \ basename))

    if filereadable(dst_path) || isdirectory(dst_path)
      call vaffle#util#echo_error(
            \ printf('File already exists. Skipped: ''%s''', dst_path))
      continue
    endif

    call rename(item.path, dst_path)

    echo printf('Moved file: ''%s'' -> ''%s''',
          \ item.basename,
          \ dst_path)
  endfor
endfunction


function! vaffle#file#rename(filer, items, new_basenames) abort
  let cwd = a:filer.dir
  let index = 0
  let renamed_paths = []

  for item in a:items
    let new_basename = a:new_basenames[index]
    let new_path = vaffle#util#normalize_path(printf('%s/%s',
          \ cwd,
          \ new_basename))
    let index += 1

    if filereadable(new_path) || isdirectory(new_path)
      call add(renamed_paths, '')
      call vaffle#util#echo_error(
            \ printf('File already exists, skipped: ''%s''', new_path))
      continue
    endif

    call rename(item.path, new_path)
    call add(renamed_paths, new_path)
    echo printf('Renamed file: ''%s'' -> ''%s''',
          \ item.basename,
          \ new_basename)
  endfor

  return renamed_paths
endfunction


let &cpoptions = s:save_cpo
