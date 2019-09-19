let s:suite = themis#suite('vaffle#util')
let s:assert = themis#helper('assert')


function! s:suite.test_normalize_path() abort
  let test_cases = [{
        \   'path': '/foo/bar/baz/',
        \   'expected': '/foo/bar/baz',
        \ }, {
        \   'path': '/',
        \   'expected': '/',
        \ }]

  for test_case in test_cases
    call s:assert.equals(
          \ vaffle#util#normalize_path(test_case.path),
          \ test_case.expected)
  endfor
endfunction


function! s:suite.test_get_last_component() abort
  let test_cases = [{
        \   'path': '/foo/bar/baz',
        \   'is_dir': 0,
        \   'expected': 'baz',
        \ }]

  for test_case in test_cases
    call s:assert.equals(
          \ vaffle#util#get_last_component(test_case.path, test_case.is_dir),
          \ test_case.expected)
  endfor
endfunction
