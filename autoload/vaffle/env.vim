let s:save_cpo = &cpoptions
set cpoptions&vim


" `vaffle#env` represents an environment to create Vaffle buffer.


function! vaffle#env#create(path) abort
  let env = {}
  let env.dir = vaffle#util#normalize_path(a:path)
  let env.cursor_paths = {}
  let env.shows_hidden_files = g:vaffle_show_hidden_files
  let env.items = []
  return env
endfunction


function! vaffle#env#inherit(env, old_env) abort
  let a:env.cursor_paths = get(
        \ a:old_env,
        \ 'cursor_paths',
        \ a:env.cursor_paths)

  let a:env.shows_hidden_files = get(
        \ a:old_env,
        \ 'shows_hidden_files',
        \ a:env.shows_hidden_files)
endfunction


function! vaffle#env#create_items(env) abort
  let env_dir = fnameescape(fnamemodify(a:env.dir, ':p'))
  let paths = vaffle#compat#glob_list(env_dir . '*')
  if a:env.shows_hidden_files
    let hidden_paths = vaffle#compat#glob_list(env_dir . '.*')
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let items =  map(
        \ copy(paths),
        \ 'vaffle#item#create(v:val)')
  call sort(items, 'vaffle#sorter#default#compare')

  let index = 0
  for item in items
    let item.index = index
    let index += 1
  endfor

  return items
endfunction


let &cpoptions = s:save_cpo
