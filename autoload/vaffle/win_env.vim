let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#win_env#create() abort
  let env = {}
  let env.altbuf = -1
  let env.prevbuf = -1
  return env
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
