let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:map_default(mode, lhs, vaffle_command, sp_args) abort
  execute printf('%smap %s %s <Plug>(vaffle-%s)',
        \ a:mode,
        \ a:sp_args,
        \ a:lhs,
        \ a:vaffle_command)
endfunction

function! s:set_up_default_mappings() abort
  " Toggle
  call s:map_default('n', '<Space>', 'toggle-current',   '<buffer> <silent>')
  call s:map_default('n', '.',       'toggle-hidden',    '<buffer> <silent>')
  call s:map_default('n', '*',       'toggle-all',       '<buffer> <silent>')
  call s:map_default('v', '<Space>', 'toggle-current',   '<buffer> <silent>')
  " Operations for selected items
  call s:map_default('n', 'd',       'delete-selected',  '<buffer> <nowait> <silent>')
  call s:map_default('n', 'x',       'fill-cmdline',     '<buffer> <silent>')
  call s:map_default('n', 'm',       'move-selected',    '<buffer> <silent>')
  call s:map_default('n', '<CR>',    'open-selected',    '<buffer> <silent>')
  call s:map_default('n', 'r',       'rename-selected',  '<buffer> <silent>')
  " Operations for a item on cursor
  call s:map_default('n', 'l',       'open-current',     '<buffer> <silent>')
  call s:map_default('n', 't',       'open-current-tab', '<buffer> <nowait> <silent>')
  " Misc
  call s:map_default('n', 'o',       'mkdir',            '<buffer> <silent>')
  call s:map_default('n', 'i',       'new-file',         '<buffer> <silent>')
  call s:map_default('n', '~',       'open-home',        '<buffer> <silent>')
  call s:map_default('n', 'h',       'open-parent',      '<buffer> <silent>')
  call s:map_default('n', 'q',       'quit',             '<buffer> <silent>')
  call s:map_default('n', 'R',       'refresh',          '<buffer> <silent>')

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

  call vaffle#chdir(a:path)
endfunction


function! s:find_lnum_for_path(filer, path) abort
  if empty(a:path)
    return 1
  endif

  let items = filter(
        \ copy(a:filer.items),
        \ 'v:val.path ==# a:path')
  if empty(items)
    return 1
  endif

  let cursor_item = items[0]
  return index(a:filer.items, cursor_item) + 1
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

  if g:vaffle_use_default_mappings
    call s:set_up_default_mappings()
  endif

  setlocal bufhidden=delete
  setlocal buftype=nowrite
  setlocal filetype=vaffle
  setlocal matchpairs=
  setlocal nobuflisted
  setlocal noswapfile
  setlocal nowrap

  let filer = vaffle#filer#create(path)
  call vaffle#filer#inherit(filer, vaffle#buffer#get_filer())
  let filer.items = vaffle#file#create_items_from_dir(
        \ filer.dir,
        \ filer.shows_hidden_files)
  call vaffle#buffer#set_filer(filer)

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

  let filer = vaffle#buffer#get_filer()
  let items = filer.items
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


function! vaffle#buffer#move_cursor_to_lnum(lnum) abort
  call cursor([a:lnum, 1, 0, 1])
endfunction


function! vaffle#buffer#restore_cursor() abort
  let filer = vaffle#buffer#get_filer()
  let cursor_path = get(filer.cursor_paths, filer.dir, '')
  let lnum = s:find_lnum_for_path(filer, cursor_path)
  call vaffle#buffer#move_cursor_to_lnum(lnum)
endfunction


function! vaffle#buffer#move_cursor_to_path(path) abort
  let filer = vaffle#buffer#get_filer()
  let lnum = s:find_lnum_for_path(filer, a:path)
  call vaffle#buffer#move_cursor_to_lnum(lnum)
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
        \ vaffle#buffer#get_filer(),
        \ '')
endfunction


function! vaffle#buffer#get_filer() abort
  let b:vaffle = get(b:, 'vaffle', {})
  return b:vaffle
endfunction


function! vaffle#buffer#set_filer(filer) abort
  let b:vaffle = a:filer
endfunction


function! vaffle#buffer#save_cursor(item) abort
  let filer = vaffle#buffer#get_filer()
  call vaffle#filer#save_cursor(filer, a:item.path)
  call vaffle#buffer#set_filer(filer)
endfunction


let &cpoptions = s:save_cpo
