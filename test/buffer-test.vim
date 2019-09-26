let s:suite = themis#suite('vaffle#buffer')
let s:assert = themis#helper('assert')


function! s:create_item(path, dir, selected) abort
  let item = vaffle#item#create(a:path, a:dir)
  let item.selected = a:selected
  return item
endfunction


function! s:suite.test_render_item() abort
  let test_cases = [{
        \   'item': s:create_item('/home/foobar', v:false, v:false),
        \   'expected': '  foobar',
        \  }, {
        \   'item': s:create_item('/home/foobar', v:true, v:false),
        \   'expected': '  foobar/',
        \  }, {
        \   'item': s:create_item('/home/foobar', v:false, v:true),
        \   'expected': '* foobar',
        \ }]

  for test_case in test_cases
    call s:assert.equals(
          \ vaffle#buffer#render_item(test_case.item),
          \ test_case.expected)
  endfor
endfunction
