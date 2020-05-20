let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:newtralize_netrw() abort
  augroup FileExplorer
    autocmd!
  augroup END
endfunction


function! s:should_init(bufnr, path) abort
  let for_vaffle = vaffle#buffer#is_for_vaffle(a:bufnr)

  if for_vaffle && !exists('b:vaffle')
    " Deleted Vaffle buffer should be initialized
    return 1
  endif

  if for_vaffle
    " Living Vaffle buffer should not be initialized
    return 0
  endif

  return isdirectory(a:path)
endfunction


function! vaffle#event#on_bufenter() abort
  call s:newtralize_netrw()

  let bufnr = bufnr('%')
  let path = expand('%:p')

  if !s:should_init(bufnr, path)
    if !vaffle#buffer#is_for_vaffle(bufnr)
      " Store bufnr of non-directory, non-vaffle buffer
      " for restoring previous buffer when quitting
      call vaffle#window#store_non_vaffle_buffer(bufnr)
    endif
    return
  endif

  call vaffle#init(path, 1)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
