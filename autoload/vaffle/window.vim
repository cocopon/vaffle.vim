let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#window#init() abort
  let win_env = extend(
        \ vaffle#win_env#create(),
        \ get(w:, 'vaffle', {}))

  if win_env.non_vaffle_bufnr == bufnr('%')
    " Exclude empty buffer used for Vaffle
    " For example:
    " :enew
    "   Created new empty buffer (bufnr: 2)
    "   Updated `non_vaffle_bufnr` (= 2)
    " :Vaffle
    "   Used created buffer (bufnr: 2) for Vaffle
    "   `non_vaffle_bufnr` is 2, but should not restore it
    let win_env.non_vaffle_bufnr = -1
  endif

  call vaffle#window#set_env(win_env)
endfunction


function! vaffle#window#store_non_vaffle_buffer(bufnr) abort
  let win_env = vaffle#window#get_env()
  let win_env.non_vaffle_bufnr = a:bufnr
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
