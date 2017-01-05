" Author:  cocopon <cocopon@me.com>
" License: MIT License


let s:save_cpo = &cpo
set cpo&vim


function! s:newtralize_netrw() abort
  augroup FileExplorer
    autocmd!
  augroup END
endfunction


function! vaffle#event#on_bufenter() abort
  call s:newtralize_netrw()

  let bufnr = bufnr('%')
  let bufname = bufname(bufnr)
  let is_vaffle_buffer = vaffle#buffer#is_for_vaffle(bufnr)
  let path = is_vaffle_buffer
        \ ? vaffle#buffer#extract_path_from_bufname(bufname)
        \ : expand('%:p')

  let should_init = is_vaffle_buffer
        \ || isdirectory(path)

  if !should_init
    if !get(g:, 'vaffle_creating_vaffle_buffer', 0)
      " Store bufnr of non-vaffle buffer to restore initial state
      call vaffle#env#set('non_vaffle_bufnr', bufnr)
    endif

    return
  endif

  call vaffle#init(path)
endfunction


function! vaffle#event#on_bufleave() abort
  call vaffle#buffer#restore_if_needed()
endfunction


let &cpo = s:save_cpo
