" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! s:set_up_default_mappings() abort
  " Toggle
  nmap <buffer> <silent> <Space>    <Plug>(vaffle-toggle-current)
  nmap <buffer> <silent> .          <Plug>(vaffle-toggle-hidden)
  nmap <buffer> <silent> *          <Plug>(vaffle-toggle-all)
  vmap <buffer> <silent> <Space>    <Plug>(vaffle-toggle-current)
  " Operations for selected items
  nmap <buffer> <nowait> <silent> d <Plug>(vaffle-delete-selected)
  nmap <buffer> <silent> m          <Plug>(vaffle-move-selected)
  nmap <buffer> <silent> <CR>       <Plug>(vaffle-open-selected)
  nmap <buffer> <silent> r          <Plug>(vaffle-rename-selected)
  " Operations for a item on cursor
  nmap <buffer> <silent> l          <Plug>(vaffle-open-current)
  " Misc
  nmap <buffer> <silent> K          <Plug>(vaffle-mkdir)
  nmap <buffer> <silent> N          <Plug>(vaffle-new-file)
  nmap <buffer> <silent> h          <Plug>(vaffle-open-parent)
  nmap <buffer> <silent> q          <Plug>(vaffle-quit)
  nmap <buffer> <silent> <C-[>      <Plug>(vaffle-quit)
  nmap <buffer> <silent> <Esc>      <Plug>(vaffle-quit)
  nmap <buffer> <silent> R          <Plug>(vaffle-refresh)
endfunction


function! s:create_line_from_item(item) abort
  return printf('%s %s',
        \ a:item.selected ? '*' : ' ',
        \ a:item.basename . (a:item.is_dir ? '/' : ''))
endfunction


function! s:generate_unique_bufname(path) abort
  let bufname = ''
  let index = 0

  while 1
    " Add index to avoid duplicated buffer name
    let bufname = fnameescape(printf('vaffle://%d/%s',
          \ index,
          \ a:path))
    if bufnr(bufname) < 0
      break
    endif

    let index += 1
  endwhile

  return bufname
endfunction


function! s:get_options_dict() abort
  return {
        \   'bufhidden':  { 'type': 'string', 'value': &bufhidden},
        \   'buftype':    { 'type': 'string', 'value': &buftype},
        \   'matchpairs': { 'type': 'string', 'value': &matchpairs},
        \   'swapfile':   { 'type': 'bool',   'value': &swapfile},
        \   'wrap':       { 'type': 'bool',   'value': &wrap},
        \ }
endfunction


function! s:restore_options() abort
  let options = vaffle#buffer#get_env().initial_options
  for option_name in keys(options)
    let option = options[option_name]
    let command = (option.type ==? 'bool')
          \ ? printf('setlocal %s%s',
          \   (option.value ? '' : 'no'),
          \   option_name)
          \ : printf('setlocal %s=%s',
          \   option_name,
          \   option.value)
    execute command
  endfor
endfunction


function! s:perform_auto_cd_if_needed(path) abort
  if !g:vaffle_auto_cd
    return
  endif

  try
    execute printf('lcd %s', fnameescape(a:path))
  catch /:E472:/
    " E472: Command failed
    " Permission denied, etc.
    call vaffle#util#echo_error(
          \ printf('Changing directory failed: ''%s''', a:path))
    return
  endtry
endfunction


function! s:get_saved_cursor_lnum() abort
  let env = vaffle#buffer#get_env()
  let cursor_paths = env.cursor_paths
  let cursor_path = get(cursor_paths, env.dir, '')
  if empty(cursor_path)
    return 1
  endif

  let items = filter(
        \ copy(env.items),
        \ 'v:val.path ==# cursor_path')
  if empty(items)
    return 1
  endif

  let cursor_item = items[0]
  return index(env.items, cursor_item) + 1
endfunction


function! vaffle#buffer#init(path) abort
  let path = vaffle#util#normalize_path(a:path)

  " Give unique name to buffer to avoid unwanted sync
  " between different windows
  execute printf('silent file %s',
        \ s:generate_unique_bufname(path))

  let initial_options = s:get_options_dict()
  setlocal bufhidden=wipe
  setlocal buftype=nowrite
  setlocal filetype=vaffle
  setlocal matchpairs=
  setlocal noswapfile
  setlocal nowrap

  if g:vaffle_use_default_mappings
    call s:set_up_default_mappings()
  endif

  let env = vaffle#env#create(path)
  call vaffle#env#inherit(env, vaffle#buffer#get_env())
  let env.initial_options = initial_options
  let env.items = vaffle#env#create_items(env)
  call vaffle#buffer#set_env(env)

  call vaffle#buffer#redraw()

  call s:perform_auto_cd_if_needed(path)
endfunction


function! vaffle#buffer#reuse(path) abort
  let path = vaffle#util#normalize_path(a:path)

  let env = vaffle#env#create(path)
  call vaffle#env#inherit(env, vaffle#buffer#get_env())
  let env.items = vaffle#env#create_items(env)
  call vaffle#buffer#set_env(env)

  call vaffle#buffer#redraw()

  call s:perform_auto_cd_if_needed(path)
endfunction


function! vaffle#buffer#is_for_vaffle(bufnr) abort
  let bufname = bufname(a:bufnr)
  return (match(bufname, '^vaffle://\d\+/') >= 0)
endfunction


function! vaffle#buffer#extract_path_from_bufname(bufnr) abort
  let bufname = bufname(a:bufnr)
  let matches = matchlist(bufname, '^vaffle://\d\+/\(.*\)$')
  return get(matches, 1, '')
endfunction


function! vaffle#buffer#restore_if_needed() abort
  if !vaffle#buffer#is_for_vaffle(bufnr('%'))
    return 0
  endif

  call s:restore_options()
  setlocal modifiable

  return 1
endfunction


function! vaffle#buffer#redraw() abort
  setlocal modifiable

  " Clear buffer before drawing items
  silent keepjumps %d

  let env = vaffle#buffer#get_env()
  let items = env.items
  if !empty(items)
    let lnum = 1
    for item in items
      let line = s:create_line_from_item(item)
      call setline(lnum, line)
      let lnum += 1
    endfor
  else
    call setline(1, '  (no items)')
  endif

  setlocal nomodifiable
  setlocal nomodified

  let initial_lnum = s:get_saved_cursor_lnum()
  call cursor([initial_lnum, 1, 0, 1])
endfunction


function! vaffle#buffer#redraw_item(item) abort
  setlocal modifiable

  let lnum = a:item.index + 1
  call setline(lnum, s:create_line_from_item(a:item))

  setlocal nomodifiable
  setlocal nomodified
endfunction


function! vaffle#buffer#duplicate() abort
  " Split buffer doesn't have `w:vaffle` so restore it from `b:vaffle`
  let w:vaffle = deepcopy(b:vaffle)

  call vaffle#file#edit(
        \ vaffle#buffer#get_env(),
        \ '')
endfunction


function! vaffle#buffer#get_env() abort
  let w:vaffle = get(w:, 'vaffle', get(b:, 'vaffle', {}))
  return w:vaffle
endfunction


function! vaffle#buffer#set_env(env) abort
  let w:vaffle = a:env
  let b:vaffle = w:vaffle
endfunction


function! vaffle#buffer#save_cursor(item) abort
  let env = vaffle#buffer#get_env()
  let env.cursor_paths[env.dir] = a:item.path
  call vaffle#buffer#set_env(env)
endfunction


let &cpo = s:save_cpo
