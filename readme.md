# operator-camelize.vim

Vim operator to convert words of `snake_case`, `camelCase` and `PascalCase`.  
This repository was forked from [tyru/operator-camelize.vim](https://github.com/tyru/operator-camelize.vim) to support `camelCase` conversion.

Key mappings example:

```vim
" foo_bar -> fooBar
map <Leader>c <Plug>(operator-to-camel)

" foo_bar -> FooBar
map <Leader>p <Plug>(operator-to-pascal)

" fooBar -> foo_bar
" FooBar -> foo_bar
map <Leader>s <Plug>(operator-to-snake)
```
