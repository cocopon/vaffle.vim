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


function! vaffle#filer#save_cursor(filer, path) abort
  let a:filer.cursor_paths[a:filer.dir] = a:path
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


let &cpoptions = s:save_cpo
