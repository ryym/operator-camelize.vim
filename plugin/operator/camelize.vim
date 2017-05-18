" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('g:loaded_operator_camelize') && g:loaded_operator_camelize
    finish
endif
let g:loaded_operator_camelize = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

if !exists('g:operator_camelize_all_upper_to_snake')
    let g:operator_camelize_all_upper_to_snake = 'nop'
endif
if !exists('g:operator_camelize_all_upper_to_pascal')
    let g:operator_camelize_all_upper_to_pascal = 'nop'
endif
if !exists('g:operator_camelize_detect_function')
    let g:operator_camelize_detect_function = 'operator#camelize#is_camelized'
endif

call operator#user#define('to-pascal', 'operator#camelize#op_to_pascal')
call operator#user#define('to-snake', 'operator#camelize#op_to_snake')
call operator#user#define('camelize-toggle', 'operator#camelize#op_camelize_toggle')


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
