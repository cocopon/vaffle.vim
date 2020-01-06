let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#renderer#render_item(item) abort
  return printf('%s %s',
        \ a:item.selected ? '*' : ' ',
        \ a:item.basename . (a:item.is_dir ? '/' : ''))
endfunction


function! vaffle#renderer#render_filer(items) abort
  if empty(a:items)
    return ['  (no items)']
  endif

  return map(copy(a:items), 'vaffle#renderer#render_item(v:val)')
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
