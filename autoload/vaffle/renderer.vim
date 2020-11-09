let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#renderer#render_item(item) abort
  if get(g:, 'vaffle_render_custom_icon', '') !=# ''
    return printf('%s %s %s',
          \ a:item.selected ? '*' : ' ',
          \ call(g:vaffle_render_custom_icon, [a:item]),
          \ a:item.basename . (a:item.is_dir ? '/' : ''))
  else
    return printf('%s %s',
          \ a:item.selected ? '*' : ' ',
          \ a:item.basename . (a:item.is_dir ? '/' : ''))
  endif
endfunction


function! vaffle#renderer#render_filer(items) abort
  if empty(a:items)
    return ['  (no items)']
  endif

  return map(copy(a:items), 'vaffle#renderer#render_item(v:val)')
endfunction

function! vaffle#renderer#render_header(path)
   return fnamemodify(a:path, ':p') . ':'
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
