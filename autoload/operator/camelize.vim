" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



function! operator#camelize#load() "{{{
    runtime! plugin/operator/camelize.vim
endfunction "}}}



" Utilities
function! s:map_text_with_regex(text, funcname, regex) "{{{
    let text = a:text
    let context = {
    \   'converted': '',
    \   'match': '',
    \}
    while text != ''
        let offset = match(text, a:regex)
        if offset ==# -1
            break
        endif
        let len = matchend(text, a:regex)

        let left          = offset == 0 ? '' : text[: offset - 1]
        let context.match = text[offset : offset + len - 1]
        let right         = text[offset + len :]

        let context.converted .= left . {a:funcname}(context)
        let text = right
    endwhile
    return context.converted . text
endfunction "}}}

" Utilities for operator
function! s:yank_range(motion_wiseness) "{{{
    " Select previously-selected range in visual mode.
    " NOTE: `normal! gv` does not work
    " when user uses operator from normal mode.

    " From http://gist.github.com/356290
    " But specialized to operator-user.

    try
        " For saving &selection. See :help :map-operator
        let sel_save = &l:selection
        let &l:selection = "inclusive"
        " Save @@.
        let reg_save     = getreg('z', 1)
        let regtype_save = getregtype('z')

        if a:motion_wiseness == 'char'
            let ex = '`[v`]"zy'
        elseif a:motion_wiseness == 'line'
            let ex = '`[V`]"zy'
        elseif a:motion_wiseness == 'block'
            let ex = '`[' . "\<C-v>" . '`]"zy'
        else
            " silent execute 'normal! `<' . a:motion_wiseness . '`>'
            echoerr 'internal error, sorry: this block never be reached'
        endif
        execute 'silent normal!' ex
        return @z
    finally
        let &l:selection = sel_save
        call setreg('z', reg_save, regtype_save)
    endtry
endfunction "}}}
function! s:paste_range(motion_wiseness, text) "{{{
    let reg_z_save     = getreg('z', 1)
    let regtype_z_save = getregtype('z')

    try
        call setreg('z', a:text,
        \   operator#user#visual_command_from_wise_name(a:motion_wiseness))
        silent normal! gv"zp
    finally
        call setreg('z', reg_z_save, regtype_z_save)
    endtry
endfunction "}}}
function! s:replace_range(funcname, pattern, motion_wiseness) "{{{
    " Yank the text in the range given by a:motion_wiseness.
    let text = s:yank_range(a:motion_wiseness)
    " Convert the text.
    let text = s:map_text_with_regex(text, a:funcname, a:pattern)
    " Paste the text to the range.
    call s:paste_range(a:motion_wiseness, text)
endfunction "}}}



" For a atom
" e.g.: 'snake' => 'Snake'
function! s:atom_to_pascal(context) "{{{
    let word = a:context.match[0] == '_' ? a:context.match[1:] : a:context.match
    return toupper(word[0]) . tolower(word[1:])
endfunction "}}}

" For a word
" e.g.: 'snake_case' => 'SnakeCase'
function! s:word_to_pascal(context) "{{{
    " NOTE: Nested sub-replace-expression can't work...omg
    " (:help sub-replace-expression)
    "
    " return substitute(tolower(a:context.match), '^[a-z]\|_\zs[a-z]'.'\C', '\=toupper(submatch(0))', 'g')

    let word = a:context.match

    if word =~# '^[A-Z]\+$' && !g:operator_camelize_convert_all_upper_word
        return word
    endif

    return s:map_text_with_regex(
    \   word,
    \   's:atom_to_pascal',
    \   '\<[a-zA-Z0-9]\+\|_[a-zA-Z0-9]\+'.'\C'
    \)
endfunction "}}}

" For <Plug>(operator-to-pascal)
function! operator#camelize#op_to_pascal(motion_wiseness) "{{{
    call s:replace_range('s:word_to_pascal', '\w\+', a:motion_wiseness)
endfunction "}}}


" For a word
" e.g.: 'snake_case' => 'snakeCase'
function! s:word_to_camel(context) "{{{
    let word = a:context.match

    if word =~# '^[A-Z]\+$' && !g:operator_camelize_convert_all_upper_word
        return word
    endif

    let pascal_word = s:map_text_with_regex(
    \   word,
    \   's:atom_to_pascal',
    \   '\<[a-zA-Z0-9]\+\|_[a-zA-Z0-9]\+'.'\C'
    \)
    return tolower(pascal_word[0]) . pascal_word[1:]
endfunction "}}}

" For <Plug>(operator-to-camel)
function! operator#camelize#op_to_camel(motion_wiseness) "{{{
    call s:replace_range('s:word_to_camel', '\w\+', a:motion_wiseness)
endfunction "}}}


" For a atom
" e.g.: 'Snake' => 'snake'
function! s:atom_to_snake(context) "{{{
    return (a:context.converted ==# '' ? '' : '_')
    \       . tolower(a:context.match)
endfunction "}}}

" For a word
" e.g.: 'snakeCase', 'SnakeCase' => 'snake_case'
function! s:word_to_snake(context) "{{{
    " NOTE: Nested sub-replace-expression can't work...omg
    " (:help sub-replace-expression)
    "
    " return substitute(a:context.match, '^[A-Z]\|[a-z]\zs[A-Z]'.'\C', '\='_' . tolower(submatch(0))', 'g')

    let word = a:context.match

    if word =~# '^[A-Z]\+$' && !g:operator_camelize_convert_all_upper_word
        return word
    endif

    return s:map_text_with_regex(
    \   word,
    \   's:atom_to_snake',
    \   '^[a-z0-9]\+\ze[A-Z]\|^[A-Z][a-z0-9]*'.'\C',
    \)
endfunction "}}}

" For <Plug>(operator-to-snake)
function! operator#camelize#op_to_snake(motion_wiseness) "{{{
    call s:replace_range('s:word_to_snake', '\w\+', a:motion_wiseness)
endfunction "}}}



" Returns true when a:word is camelized.
" Returns false otherwise.
" e.g.: 'CamelCase' => true
" e.g.: 'camelCase' => true
" e.g.: 'snake_case' => false
" e.g.: 'camelCase_' => false
" e.g.: 'CamelCase_' => false
" e.g.: 'vim' => false
function! operator#camelize#is_camelized(word) "{{{
    " upper camel case: e.g., 'CamelCase'
    if a:word =~# '^[A-Z][A-Za-z0-9]\+$' | return 1 | endif
    " lower camel case: e.g., 'camelCase'
    if a:word =~# '^[a-z][A-Za-z0-9]*[A-Z]\+[A-Za-z0-9]*$' | return 1 | endif
    return 0
endfunction "}}}

" For a word
" e.g.: 'SnakeCase', 'snakeCase' => 'snake_case'
" e.g.: 'snake_case' => 'SnakeCase'
function! s:toggle_pascal_snake(context) "{{{
    return s:toggle_word(a:context, 's:word_to_pascal')
endfunction "}}}

" For a word
" e.g.: 'SnakeCase', 'snakeCase' => 'snake_case'
" e.g.: 'snake_case' => 'snakeCase'
function! s:toggle_camel_snake(context) "{{{
    return s:toggle_word(a:context, 's:word_to_camel')
endfunction "}}}

function! s:toggle_word(context, from_snake) "{{{
    let camelized = g:operator_camelize_detect_function
    if {camelized}(a:context.match)
        return s:word_to_snake(a:context)
    else
        return {a:from_snake}(a:context)
    endif
endfunction "}}}

" For <Plug>(operator-toggle-pascal-snake)
function! operator#camelize#op_toggle_pascal_snake(motion_wiseness) "{{{
    call s:replace_range('s:toggle_pascal_snake', '\w\+', a:motion_wiseness)
endfunction "}}}

" For <Plug>(operator-toggle-camel-snake)
function! operator#camelize#op_toggle_camel_snake(motion_wiseness) "{{{
    call s:replace_range('s:toggle_camel_snake', '\w\+', a:motion_wiseness)
endfunction "}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
