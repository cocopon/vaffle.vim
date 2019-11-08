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
  let path = expand('%:p')

  let should_init = isdirectory(path)
  if !should_init
    " Store bufnr of non-directory buffer
    " for restoring previous buffer when quitting
    call vaffle#window#store_non_vaffle_buffer(bufnr)
    return
  endif

  call vaffle#init(path)
endfunction


let &cpoptions = s:save_cpo
