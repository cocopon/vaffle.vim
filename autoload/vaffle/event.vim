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

  let path = expand('%:p')

  let is_nofile_buffer = empty(path)
  let is_normal_buffer_for_file = !empty(path) && !isdirectory(path)
  if is_nofile_buffer
        \ || is_normal_buffer_for_file
    call vaffle#buffer#restore_if_needed()

    " Store bufnr of non-vaffle buffer to restore initial state
    if &filetype !=? 'vaffle'
      call vaffle#env#set('non_vaffle_bufnr', bufnr('%'))
    endif

    return
  endif

  call vaffle#init(path)
endfunction


let &cpo = s:save_cpo
