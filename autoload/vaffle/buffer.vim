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
  " Add prefix `#:` (waffle!) to avoid truncating path
  " with statusline item `%t`
  let bufname = fnameescape(printf('#:%s', a:path))

  let index = 2
  while bufnr(bufname) >= 0
    " Add index to avoid duplicated buffer name
    let bufname = fnameescape(printf('#%d:%s',
          \ index,
          \ a:path))
    let index += 1
  endwhile

  return bufname
endfunction


function! s:store_options() abort
  let options = {
        \   'bufhidden':  { 'type': 'string', 'value': &bufhidden},
        \   'buftype':    { 'type': 'string', 'value': &buftype},
        \   'matchpairs': { 'type': 'string', 'value': &matchpairs},
        \   'swapfile':   { 'type': 'bool',   'value': &swapfile},
        \   'wrap':       { 'type': 'bool',   'value': &wrap},
        \ }
  call vaffle#env#set(
        \ 'initial_options',
        \ options)
endfunction


function! s:restore_options() abort
  let options = vaffle#env#get().initial_options
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


function! s:should_restore() abort
  if &filetype ==? 'vaffle'
    " Active Vaffle buffer
    return 0
  endif

  if !has_key(vaffle#env#get(), 'restored')
    " Non-vaffle buffer
    return 0
  endif

  return !vaffle#env#get().restored
endfunction


function! vaffle#buffer#init(path) abort
  let prev_bufnr = bufnr('%')
  let new_path = vaffle#util#normalize_path(a:path)

  " Create new `nofile` buffer to avoid unwanted sync
  " between different windows
  enew
  execute printf('silent file %s',
        \ s:generate_unique_bufname(new_path))

  call s:store_options()
  setlocal bufhidden=wipe
  setlocal buftype=nowrite
  setlocal filetype=vaffle
  setlocal matchpairs=
  setlocal noswapfile
  setlocal nowrap

  " Delete unused directory buffer
  if isdirectory(bufname(prev_bufnr))
    execute printf('bwipeout! %d',
          \ prev_bufnr)
  endif

  call vaffle#env#set_up(new_path)
  call vaffle#buffer#redraw()

  if g:vaffle_use_default_mappings
    call s:set_up_default_mappings()
  endif

  if g:vaffle_auto_cd
    try
      execute printf('lcd %s', fnameescape(new_path))
    catch /:E472:/
      " E472: Command failed
      " Permission denied, etc.
      call vaffle#util#echo_error(
            \ printf('Changing directory failed: ''%s''', new_path))
      return
    endtry
  endif
endfunction


function! vaffle#buffer#restore_if_needed() abort
  if !s:should_restore()
    return 0
  endif

  call s:restore_options()
  setlocal modifiable

  call vaffle#env#set('restored', 1)

  return 1
endfunction


function! vaffle#buffer#redraw() abort
  setlocal modifiable

  " Clear buffer before drawing items
  silent keepjumps %d

  let items = vaffle#env#get().items
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

  let initial_lnum = 1
  let cursor_item = vaffle#env#restore_cursor()
  if !empty(cursor_item)
    let initial_lnum = index(items, cursor_item) + 1
  endif
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
  call vaffle#env#restore_from_buffer()
  call vaffle#file#edit(
        \ vaffle#env#get(),
        \ '')
endfunction


let &cpo = s:save_cpo
