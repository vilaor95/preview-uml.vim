" preview_uml
" Author: skanehira
" License: MIT

let s:preview_bufname = 'preview_uml'

if has('nvim')
  function! s:win_execute(winid, cmd) abort
    let curwinid = win_getid()
    call win_gotoid(a:winid)
    call execute(a:cmd)
    call win_gotoid(curwinid)
  endfunction
else
  let s:win_execute = function('win_execute')
endif

function! preview_uml#preview() abort
  augroup preview_uml
    au!
    au BufWritePost <buffer> call <SID>update()
  augroup END

  call s:init()
  let s:url = get(g:, 'preview_uml_url', 'http://localhost:8888')

  call <SID>update()
endfunction

function! s:init() abort
  let edit_winid = win_getid()

  let opener = get(g:, 'preview_uml_opener', 'new')
  if bufexists(s:preview_bufname)
    let winid = bufwinid(s:preview_bufname)
    if winid is# -1
      execute opener
      execute 'b' s:preview_bufname
    endif
  else
    execute opener s:preview_bufname
    let s:preview = {
          \ 'bufid': bufnr(),
          \ 'winid': win_getid()
          \ }
    setlocal buftype=nofile nolist nowrap
    nnoremap <buffer> <silent> q :bw!<CR>
  endif

  call win_gotoid(edit_winid)
endfunction

function! s:update() abort
  let body = getline(1, '$')
  if empty(body)
    return
  endif

  let cmd = printf('docker run -v %s:/data plantuml/plantuml -ttxt %s', expand("%:p:h"), expand("%"))
  let resp = systemlist(cmd)

  "let cmd = printf('curl -X POST -s -i %s/form -d "text=%s"', s:url,
  "      \ escape(join(body, "\n"), '"'))
  "let resp = systemlist(cmd)
  "let location = filter(resp, 'v:val =~ "Location"')
  "if empty(location)
  "  call <SID>echo_err('invalid response')
  "  call s:win_execute(s:preview.winid, 'bw!')
  "  augroup preview_uml | au! | augroup END
  "  return
  "endif

  "let url = substitute(trim(location[0][10:]), 'uml', 'txt', 'g')
  "let resp = systemlist(printf('curl -s %s', url))

  let resp = readfile(expand("%:r") . ".atxt")

  call s:win_execute(s:preview.winid, '%d_')
  call setbufline(s:preview.bufid, 1, resp)
endfunction

function! s:echo_err(msg) abort
  echohl ErrorMsg
  echom '[preview-uml]' a:msg
  echohl None
endfunction
