let s:save_cpo = &cpoptions
set cpoptions&vim


if exists('g:loaded_vaffle')
  finish
endif
let g:loaded_vaffle = 1


augroup vaffle_vim
  autocmd!
  autocmd BufEnter * call vaffle#event#on_bufenter()
augroup END


function! s:set_up_default_config()
  let config_dict = {
        \   'vaffle_auto_cd': 0,
        \   'vaffle_force_delete': 0,
        \   'vaffle_show_hidden_files': 0,
        \   'vaffle_use_default_mappings': 1,
        \   'vaffle_open_current_split_position': 'topleft',
        \   'vaffle_open_current_vsplit_position': 'rightbelow',
        \ }

  for var_name in keys(config_dict)
    let g:[var_name] = get(
          \ g:,
          \ var_name,
          \ config_dict[var_name])
  endfor
endfunction

call s:set_up_default_config()

command! -bar -nargs=? -complete=dir Vaffle call vaffle#init(<f-args>)


" Toggle
nnoremap <silent> <Plug>(vaffle-toggle-all)           :<C-u>call vaffle#toggle_all()<CR>
nnoremap <silent> <Plug>(vaffle-toggle-hidden)        :<C-u>call vaffle#toggle_hidden()<CR>
nnoremap <silent> <Plug>(vaffle-toggle-current)       :<C-u>call vaffle#toggle_current('n')<CR>
vnoremap <silent> <Plug>(vaffle-toggle-current)       :<C-u>call vaffle#toggle_current('v')<CR>
" Operations for selected items
nnoremap <silent> <Plug>(vaffle-delete-selected)      :<C-u>call vaffle#delete_selected()<CR>
nnoremap <silent> <Plug>(vaffle-fill-cmdline)         :<C-u>call vaffle#fill_cmdline()<CR>
nnoremap <silent> <Plug>(vaffle-move-selected)        :<C-u>call vaffle#move_selected()<CR>
nnoremap <silent> <Plug>(vaffle-open-selected)        :<C-u>call vaffle#open_selected('')<CR>
nnoremap <silent> <Plug>(vaffle-open-selected-split)  :<C-u>call vaffle#open_selected('split')<CR>
nnoremap <silent> <Plug>(vaffle-open-selected-vsplit) :<C-u>call vaffle#open_selected('vsplit')<CR>
nnoremap <silent> <Plug>(vaffle-rename-selected)      :<C-u>call vaffle#rename_selected()<CR>
" Operations for a item on cursor
nnoremap <silent> <Plug>(vaffle-open-current)         :<C-u>call vaffle#open_current('')<CR>
nnoremap <silent> <Plug>(vaffle-open-current-tab)     :<C-u>call vaffle#open_current('tab')<CR>
" Misc
nnoremap <silent> <Plug>(vaffle-mkdir)                :<C-u>call vaffle#mkdir()<CR>
nnoremap <silent> <Plug>(vaffle-new-file)             :<C-u>call vaffle#new_file()<CR>
nnoremap <silent> <Plug>(vaffle-open-home)            :<C-u>call vaffle#open('~')<CR>
nnoremap <silent> <Plug>(vaffle-open-parent)          :<C-u>call vaffle#open_parent()<CR>
nnoremap <silent> <Plug>(vaffle-open-root)            :<C-u>call vaffle#open('/')<CR>
nnoremap <silent> <Plug>(vaffle-quit)                 :<C-u>call vaffle#quit()<CR>
nnoremap <silent> <Plug>(vaffle-refresh)              :<C-u>call vaffle#refresh()<CR>


let &cpoptions = s:save_cpo
