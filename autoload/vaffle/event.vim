let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:newtralize_netrw() abort
  augroup FileExplorer
    autocmd!
  augroup END
endfunction


function! vaffle#event#on_bufenter() abort
  call s:newtralize_netrw()

  let bufnr = bufnr('%')
  let is_vaffle_buffer = vaffle#buffer#is_for_vaffle(bufnr)
  let path = expand('%:p')

  let should_init = is_vaffle_buffer
        \ || isdirectory(path)

  if !should_init
    " Store bufnr of non-directory buffer to back to initial buffer
    call vaffle#window#store_non_vaffle_buffer(bufnr)
    return
  endif

  call vaffle#init(path)
endfunction


function! vaffle#event#on_bufleave() abort
  if vaffle#buffer#is_for_vaffle(bufnr('%'))
    call vaffle#buffer#save_cursor_at_current_item()
  endif
endfunction


let &cpoptions = s:save_cpo
