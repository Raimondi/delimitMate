# delimitMate

> Vim plugin for automatic closing of quotes, parenthesis, brackets, etc.

## Installation

- [plug.vim](https://github.com/junegunn/vim-plug)

```vim
Plug 'Raimondi/delimitMate'
```

## Features

### Automatic closing & exiting

```
  Type     |  You get
=======================
   (       |    (|)
-----------|-----------
   ()      |    ()|
-----------|-----------
(<S-Tab>   |    ()|
-----------|-----------
{("<C-G>g  |  {("")}|
```

### Expansion of space and CR

Expand `<Space>` to:

```
You start with  |  You get
==============================
    (|)         |    ( | )
```

Expand `<CR>` to:

```
You start with   |  You get
==============================
    (|)         |    (
                |      |
                |    )
```

### Backspace

```
  What  |      Before       |      After
==============================================
  <BS>  |  call expand(|)   |  call expand|
--------|-------------------|-----------------
  <BS>  |  call expand( | ) |  call expand(|)
--------|-------------------|-----------------
  <BS>  |  call expand(     |  call expand(|)
        |  |                |
        |  )                |
--------|-------------------|-----------------
 <S-BS> |  call expand(|)   |  call expand(|
```

### Smart Quotes

```
 What |    Before    |     After
=======================================
  "   |  Text |      |  Text "|"
  "   |  "String|    |  "String"|
  "   |  let i = "|  |  let i = "|"
  'm  |  I|          |  I'm|
```

### BALANCING MATCHING PAIRS

```
e.g. typing at the "|": >

 What |    Before    |     After
=======================================
  (   |  function|   |  function(|)
  (   |  |var        |  (|var
```
