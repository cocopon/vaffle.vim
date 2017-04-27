let s:save_cpo = &cpoptions
set cpoptions&vim


let s:buffer_name = 'vaffle [rename]'


function! s:set_up_syntax(items) abort
  syntax match vaffleRenamed '^.\+$'

  let lnum = 1
  for item in a:items
    execute printf('syntax match vaffleNotRenamed ''^\%%%dl%s$''',
          \ lnum,
          \ item.basename)
    let lnum += 1
  endfor

  highlight! default link vaffleNotRenamed Normal
  highlight! default link vaffleRenamed Special
endfunction


" Currently Vint doesn't have AutocmdParser so it marked as unused variable
" https://github.com/Kuniwak/vint/pull/120
" vint: -ProhibitUnusedVariable
function! s:on_bufwrite() abort
  let new_basenames = getline(1, line('$'))

  call vaffle#file#rename(
        \ b:vaffle.parent_env,
        \ b:vaffle.items,
        \ new_basenames)
  set nomodified

  call s:redraw_parent_buffer()
endfunction
" vint: +ProhibitUnusedVariable


function! s:redraw_parent_buffer() abort
  let win_ids = vaffle#compat#win_findbuf(b:vaffle.parent_bufnr)
  if empty(win_ids)
    return
  endif

  let win_id = vaffle#compat#win_getid()
  " Redraw parent buffer if found
  if vaffle#compat#win_gotoid(win_ids[0])
    call vaffle#refresh()

    " ...and back to original window
    call vaffle#compat#win_gotoid(win_id)
  endif
endfunction


function! vaffle#rename_buffer#new(items) abort
  let bufnr = bufnr(s:buffer_name)
  if bufnr >= 0
    " Close existing rename buffer if exists
    execute printf('bwipeout %d', bufnr)
  endif

  let parent_env = vaffle#buffer#get_env()
  let parent_bufnr = bufnr('%')

  vnew
  file vaffle [rename]

  let lnum = 1
  for item in a:items
    call setline(lnum, item.basename)
    let lnum += 1
  endfor
  set nomodified

  setlocal buftype=acwrite
  setlocal filetype=vaffle-rename
  setlocal noswapfile
  setlocal nowrap

  let b:vaffle = {}
  let b:vaffle.parent_env = parent_env
  let b:vaffle.parent_bufnr = parent_bufnr
  let b:vaffle.items = a:items

  call s:set_up_syntax(a:items)

  augroup vaffle-rename
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:on_bufwrite()
  augroup END
endfunction


let &cpoptions = s:save_cpo
