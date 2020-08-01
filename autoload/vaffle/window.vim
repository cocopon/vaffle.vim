let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:buffer_valid(bufnr)
  return bufexists(a:bufnr) && (getbufvar(a:bufnr, '&filetype') !=? 'vaffle')
endfunction


function! vaffle#window#init() abort
  let win_env = extend(
        \ vaffle#win_env#create(),
        \ get(w:, 'vaffle', {}))


  if has_key(win_env, 'altbuf') && win_env.altbuf == bufnr('%')
    let win_env.altbuf = -1
  endif

  if has_key(win_env, 'prevbuf') && win_env.prevbuf == bufnr('%')
    let win_env.prevbuf = -1
  endif

  call vaffle#window#set_env(win_env)
endfunction


function! vaffle#window#store_non_vaffle_buffer(bufnr) abort
  let win_env = vaffle#window#get_env()

  let d = {}
  let d.prevbuf = s:buffer_valid(a:bufnr) || !has_key(win_env, 'prevbuf')
    \ ? 0+a:bufnr : win_env.prevbuf
  if !s:buffer_valid(d.prevbuf)
    let d.prevbuf = has_key(win_env, 'prevbuf') && s:buffer_valid(win_env.prevbuf)
        \ ? win_env.prevbuf : bufnr('#')
  endif

  let d.altbuf = s:buffer_valid(bufnr('#')) || !has_key(win_env, 'altbuf')
    \ ? 0+bufnr('#') : win_env.altbuf

  if has_key(win_env, 'altbuf') && (d.altbuf == d.prevbuf || !s:buffer_valid(d.altbuf))
    let d.altbuf = win_env.altbuf
  endif

  let win_env = d
  call vaffle#window#set_env(win_env)
endfunction


function! vaffle#window#get_env() abort
  return get(w:, 'vaffle', {})
endfunction


function! vaffle#window#set_env(win_env) abort
  let w:vaffle = a:win_env
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
