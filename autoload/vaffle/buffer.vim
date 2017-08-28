let s:save_cpo = &cpoptions
set cpoptions&vim


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
  nmap <buffer> <silent> o          <Plug>(vaffle-mkdir)
  nmap <buffer> <silent> i          <Plug>(vaffle-new-file)
  nmap <buffer> <silent> h          <Plug>(vaffle-open-parent)
  nmap <buffer> <silent> q          <Plug>(vaffle-quit)
  nmap <buffer> <silent> R          <Plug>(vaffle-refresh)

  " Removed <Esc> mappings because they cause a conflict with arrow keys in terminal...
  " In terminal, arrow keys are simulated as follows:
  "   <Up>:    ^[OA
  "   <Down>:  ^[OB
  "   <Right>: ^[OC
  "   <Left>:  ^[OD
  " These keys contain ^[ (equivalent to <Esc>), so they cause quitting a Vaffle buffer.
  " nmap <buffer> <silent> <Esc>      <Plug>(vaffle-quit)
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


function! vaffle#buffer#init(path) abort
  call s:clean_up_outdated_buffers()

  let path = vaffle#util#normalize_path(a:path)

  " Give unique name to buffer to avoid unwanted sync
  " between different windows
  execute printf('silent file %s',
        \ s:generate_unique_bufname(path))

  setlocal bufhidden=delete
  setlocal buftype=nowrite
  setlocal filetype=vaffle
  setlocal matchpairs=
  setlocal nobuflisted
  setlocal noswapfile
  setlocal nowrap

  if g:vaffle_use_default_mappings
    call s:set_up_default_mappings()
  endif

  let env = vaffle#env#create(path)
  call vaffle#env#inherit(env, vaffle#buffer#get_env())
  let env.items = vaffle#env#create_items(env)
  call vaffle#buffer#set_env(env)

  call vaffle#buffer#redraw()

  call s:perform_auto_cd_if_needed(path)
endfunction


function! vaffle#buffer#extract_path_from_bufname(bufname) abort
  let matches = matchlist(a:bufname, '^vaffle://\d\+/\(.*\)$')
  return get(matches, 1, '')
endfunction


function! vaffle#buffer#is_for_vaffle(bufnr) abort
  let bufname = bufname(a:bufnr)
  return !empty(vaffle#buffer#extract_path_from_bufname(bufname))
endfunction


function! vaffle#buffer#redraw() abort
  setlocal modifiable

  " Clear buffer before drawing items
  silent keepjumps %delete _

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

  call vaffle#buffer#restore_cursor()
endfunction


function! vaffle#buffer#restore_cursor() abort
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
  call vaffle#file#edit(
        \ vaffle#buffer#get_env(),
        \ '')
endfunction


function! vaffle#buffer#get_env() abort
  let b:vaffle = get(b:, 'vaffle', {})
  return b:vaffle
endfunction


function! vaffle#buffer#set_env(env) abort
  let b:vaffle = a:env
endfunction


function! vaffle#buffer#save_cursor(item) abort
  let env = vaffle#buffer#get_env()
  let env.cursor_paths[env.dir] = a:item.path
  call vaffle#buffer#set_env(env)
endfunction


let &cpoptions = s:save_cpo
