" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#file#open(items) abort
  if len(a:items) == 1
    let path = a:items[0].path
    if isdirectory(path)
      call vaffle#init(path)
    else
      execute printf('edit %s', fnameescape(a:items[0].path))
    endif
    return
  endif

  for item in a:items
    execute printf('split %s', fnameescape(item.path))
  endfor
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


function! vaffle#file#mkdir(env, name) abort
  let path = vaffle#util#normalize_path(printf('%s/%s',
        \ a:env.dir,
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


function! vaffle#file#edit(env, name) abort
  let path = vaffle#util#normalize_path(printf('%s/%s',
        \ a:env.dir,
        \ a:name))
  execute printf('edit %s', fnameescape(path))
endfunction


function! vaffle#file#move(env, items, dst_name) abort
  let dst_dir = vaffle#util#normalize_path(printf('%s/%s',
        \ a:env.dir,
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


function! vaffle#file#rename(env, items, new_basenames) abort
  let cwd = a:env.dir
  let index = 0
  for item in a:items
    let new_basename = a:new_basenames[index]
    let new_path = vaffle#util#normalize_path(printf('%s/%s',
          \ cwd,
          \ new_basename))

    if filereadable(new_path) || isdirectory(new_path)
      call vaffle#util#echo_error(
            \ printf('File already exists, skipped: ''%s''', new_path))
      continue
    endif

    call rename(item.path, new_path)

    echo printf('Renamed file: ''%s'' -> ''%s''',
          \ item.basename,
          \ new_basename)

    let index += 1
  endfor
endfunction


let &cpoptions = s:save_cpo
