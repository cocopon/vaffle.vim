let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#filer#create(path) abort
  return {
        \   'cursor_paths': {},
        \   'dir': vaffle#util#normalize_path(a:path),
        \   'items': [],
        \   'shows_hidden_files': g:vaffle_show_hidden_files,
        \ }
endfunction


function! vaffle#filer#inherit(filer, old_filer) abort
  let a:filer.cursor_paths = get(
        \ a:old_filer,
        \ 'cursor_paths',
        \ a:filer.cursor_paths)

  let a:filer.shows_hidden_files = get(
        \ a:old_filer,
        \ 'shows_hidden_files',
        \ a:filer.shows_hidden_files)
endfunction


function! vaffle#filer#create_items(filer) abort
  let filer_dir = fnameescape(fnamemodify(a:filer.dir, ':p'))
  let paths = vaffle#compat#glob_list(filer_dir . '*')
  if a:filer.shows_hidden_files
    let hidden_paths = vaffle#compat#glob_list(filer_dir . '.*')
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let items =  map(
        \ copy(paths),
        \ 'vaffle#item#from_path(v:val)')
  call sort(items, 'vaffle#sorter#default#compare')

  let index = 0
  for item in items
    let item.index = index
    let index += 1
  endfor

  return items
endfunction


let &cpoptions = s:save_cpo
