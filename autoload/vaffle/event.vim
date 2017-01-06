" Author:  cocopon <cocopon@me.com>
" License: MIT License


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

  " Store bufnr of non-directory buffer to back to initial buffer
  if !should_init
    let env = vaffle#buffer#get_env()
    let env.non_vaffle_bufnr = bufnr
    call vaffle#buffer#set_env(env)

    return
  endif

  call vaffle#init(path)
endfunction


function! vaffle#event#on_bufleave() abort
  call vaffle#buffer#restore_if_needed()
endfunction


let &cpoptions = s:save_cpo
