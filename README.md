    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMM  MMMMMMMMM  MMMMMMMMMMMMMMMMMMMMMMMMMM  MMMMM  MMMMMMMMMMMMMMMMMMMMM
    MMMM  MMMMMMMMM  MMMMMMMMMMMMMMMMMMMMMMMMMM   MMM   MMMMMMMMMMMMMMMMMMMMM
    MMMM  MMMMMMMMM  MMMMMMMMMMMMMMMMMMMMM  MMM  M   M  MMMMMMMMMM  MMMMMMMMM
    MMMM  MMM   MMM  MM  MM  M  M MMM  MM    MM  MM MM  MMM   MMM    MMM   MM
    MM    MM  M  MM  MMMMMM        MMMMMMM  MMM  MMMMM  MM  M  MMM  MMM  M  M
    M  M  MM     MM  MM  MM  M  M  MM  MMM  MMM  MMMMM  MMMMM  MMM  MMM     M
    M  M  MM  MMMMM  MM  MM  M  M  MM  MMM  MMM  MMMMM  MMM    MMM  MMM  MMMM
    M  M  MM  M  MM  MM  MM  M  M  MM  MMM  MMM  MMMMM  MM  M  MMM  MMM  M  M
    MM    MMM   MMM  MM  MM  M  M  MM  MMM   MM  MMMMM  MMM    MMM   MMM   MM
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM



This plug-in provides automatic closing of quotes, parenthesis, brackets, etc., besides some other related features that should make your time in insert mode a little bit easier, like syntax awareness (will not insert the closing delimiter in comments and other configurable regions), visual wrapping, <CR> and <Space> expansions (off by default), and some more.

Most of the features can be modified or disabled permanently, using global variables, or on a FileType basis, using :autocmd. With a couple of exceptions and limitations, this features don't brake undo, redo or history.
