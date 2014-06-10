`org-weave` takes an [Org](http://orgmode.org) file as an argument and produces, on standard output, source code for typeset documentation.

Currently, the only format supported is `gfm` ([GitHub flavored Markdown](http://github.github.com/github-flavored-markdown/)).

# Usage

```sh
org-weave [options] file.org > document
```

Options:

<table id="toptions" border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />
</colgroup>
<tbody>
<tr>
<td class="left">-E EMACS</td>
<td class="left">Specify the Emacs executable. Default value is 'emacs24-nox'</td>
</tr>


<tr>
<td class="left">-O OPTIONS</td>
<td class="left">Specify the options to pass to Emacs. Default value is '-Q &#x2013;batch'</td>
</tr>


<tr>
<td class="left">-q</td>
<td class="left">Enable quick expansion of noweb references</td>
</tr>


<tr>
<td class="left">&#xa0;</td>
<td class="left">(see variable org-babel-use-quick-and-dirty-noweb-expansion).</td>
</tr>


<tr>
<td class="left">-L ORGDIR</td>
<td class="left">Specify an alternate directory for Org libs.</td>
</tr>


<tr>
<td class="left">-f FORMAT</td>
<td class="left">Specify the output format.</td>
</tr>


<tr>
<td class="left">&#xa0;</td>
<td class="left">Currently, only 'gfm' (GitHub flavored Mardown) is supported.</td>
</tr>


<tr>
<td class="left">-V</td>
<td class="left">Show version and exit</td>
</tr>
</tbody>
</table>

# Source code

## Shell code



-   Initial variables

    ```sh
    DIR=`pwd`
    FILES=""
    ORGDIR="/path/to/alternate/org-mode"
    QUICK_EXPANSION=nil
    EMACS=<<emacs>>
    EMACS_OPTS="-Q --batch"
    FLAVOR=gfm
    VERSION=0.1
    ```
    
    `<<emacs>>` =
    
    ```sh
    emacs24-nox
    ```

-   Help function

    ```sh
    read -d '' help_string <<"EOF"
    Usage: <<usage>>
    
    <<format-options(toptions,fmt="%-15s %s")>>
    EOF
    
    help () {
      echo -ne "$help_string\n"
    }
    ```

-   Main part

    Let's deal with command line options
    
    ```sh
    while getopts "hE:O:L:f:qV" option "$@"; do
      case $option in
        h) help && exit 0 ;;
        E) EMACS="$OPTARG" ;;
        O) EMACS_OPTS="$OPTARG" ;;
        q) QUICK_EXPANSION=t ;;
        f) FLAVOR="$OPTARG" ;;
        L) ORGDIR="$OPTARG" ;;
        V) echo "$(basename $0) $VERSION" && exit 0 ;;
      esac
    done ; shift $((OPTIND -1))
    ```
    
    We need a file as an argument
    
    ```sh
    [ "$1" ] || { help && exit 1; }
    file="$1"
    ```
    
    For now, only gfm is supported
    
    ```sh
    [ "$FLAVOR" = "gfm" ] || { help && exit 1; }
    ```
    
    Create a temporary file
    
    ```sh
    out=$(tempfile)
    ```
    
    Now, execute emacs&#x2026;
    
    ```sh
    $EMACS ${EMACS_OPTS} --eval "(progn
      <<escape-quotes(elisp-code)>>)"
    ```

## Elisp code

When `ORGDIR` actually exists, load Org libraries from this directory. Otherwise, we'll use the ones that ship with Emacs or were installed using `package.el`

```lisp
(package-initialize)
(when (file-accessible-directory-p "$ORGDIR")
   (add-to-list 'load-path (expand-file-name "$ORGDIR/lisp/"))
   (add-to-list 'load-path (expand-file-name "$ORGDIR/contrib/lisp/" t)))
```

Require the necessary libs (only `ox-gfm` for now)

```lisp
(require 'ox-gfm)
```

Set `org-babel-use-quick-and-dirty-noweb-expansion` to the value of `QUICK_EXPANSION`

```lisp
(setq org-babel-use-quick-and-dirty-noweb-expansion ${QUICK_EXPANSION})
```

Do not require confirmation before evaluating code blocks

```lisp
(setq org-confirm-babel-evaluate nil)
```

Open the file within emacs;

```lisp
(find-file (expand-file-name "$file" "$DIR"))
```

export it

```lisp
(princ (org-export-as 'gfm))
```

## Utility functions

`<<escape-quotes>>` =

```lisp
(save-match-data
  (replace-regexp-in-string "\"" "\\\\\"" str-val))
```

Used to escape the quotes within the elisp code before embedding it into the shell code, in order to preserve readability.

`<<format-options>>` =

```lisp
(mapconcat 
  (lambda (row)
    (format fmt (car row) (cadr row))) table "\n")
```

Used to format the options table.
