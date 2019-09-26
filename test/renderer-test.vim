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
          \ vaffle#renderer#render_item(test_case.item),
          \ test_case.expected)
  endfor
endfunction


function! s:suite.test_render_filer() abort
  let test_cases = [{
        \   'items': [
        \     s:create_item('/home/dir', v:true, v:true),
        \     s:create_item('/home/file', v:false, v:false),
        \   ],
        \   'expected': [
        \     '* dir/',
        \     '  file',
        \   ],
        \ }, {
        \   'items': [],
        \   'expected': [
        \     '  (no items)',
        \   ],
        \ }]

  for test_case in test_cases
    let lines = vaffle#renderer#render_filer(test_case.items)

    let index = 0
    for line in lines
      call s:assert.equals(
            \ line,
            \ test_case.expected[index])
      let index += 1
    endfor
  endfor
endfunction
