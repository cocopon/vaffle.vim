let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#win_env#create() abort
  let env = {}
  let env.non_vaffle_bufnr = -1
  return env
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
