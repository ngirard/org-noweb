`org-tangle` takes one or several [Org](http://orgmode.org) files as arguments and produces programs

# Usage

```sh
org-tangle [options] file1.org [file2.org ...]
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
<td class="left">-l lang1,lang2</td>
<td class="left">List of languages which can be evaluated in Org buffers.</td>
</tr>


<tr>
<td class="left">&#xa0;</td>
<td class="left">By default, only emacs-lisp is loaded</td>
</tr>


<tr>
<td class="left">&#xa0;</td>
<td class="left">(see variable org-babel-load-languages)</td>
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
    while getopts "hE:O:L:l:qV" option "$@"; do
      case $option in
        h) help && exit 0 ;;
        E) EMACS="$OPTARG" ;;
        O) EMACS_OPTS="$OPTARG" ;;
        q) QUICK_EXPANSION=t ;;
        l) LANGUAGES="$OPTARG" ;;
        L) ORGDIR="$OPTARG" ;;
        V) echo "$(basename $0) $VERSION" && exit 0 ;;
      esac
    done ; shift $((OPTIND -1))
    ```
    
    We need at least one file as an argument
    
    ```sh
    [ "$1" ] || { help && exit 1; }
    ```
    
    Wrap each argument in the code required to call tangle on it
    
    ```sh
    for i in $@; do
          FILES="$FILES \"$i\""
    done
    ```
    
    Create a temporary file
    
    ```sh
    out=$(mktemp)
    ```
    
    Now, execute emacs&#x2026;
    
    ```sh
    $EMACS ${EMACS_OPTS} --eval "(progn
      <<escape-quotes(elisp-code)>>)"
    ```
    
    &#x2026;saving its output to a temporary file&#x2026;
    
    ```sh
    >${out} 2>&1
    ```
    
    &#x2026;and its return value.
    
    ```sh
    ret=$?
    ```
    
    If things went fine, display the number of tangled blocs
    
    ```sh
    if [ ${ret} -eq 0 ]; then
      grep -i tangled ${out}
    ```
    
    Otherwise, display the whole output for the user to further investigate
    
    ```sh
    else
      cat ${out}
    fi
    ```
    
    Finally, exit with the same value as Emacs
    
    ```sh
    exit ${ret}
    ```

## Elisp code

When `ORGDIR` actually exists, load Org libraries from this directory. Otherwise, we'll use the ones that ship with Emacs or were installed using `package.el`

```lisp
(package-initialize)
(when (file-accessible-directory-p "$ORGDIR")
   (add-to-list 'load-path (expand-file-name "$ORGDIR/lisp/"))
   (add-to-list 'load-path (expand-file-name "$ORGDIR/contrib/lisp/" t)))
```

Require Org libs

```lisp
(require 'org)
(require 'ob)
(require 'ob-tangle)
```

Set `org-babel-use-quick-and-dirty-noweb-expansion` to the value of `QUICK_EXPANSION`

```lisp
(setq org-babel-use-quick-and-dirty-noweb-expansion ${QUICK_EXPANSION})
```

Do not require confirmation before evaluating code blocks

```lisp
(setq org-confirm-babel-evaluate nil)
```

Load the languages specified via the `-l` option, if any

```lisp
(unless (equal "$LANGUAGES" "")
  (org-babel-do-load-languages
    'org-babel-load-languages
    (mapcar 
      (lambda (str) (cons (make-symbol str) t))
      (split-string "$LANGUAGES" ","))))
```

For each file in `FILES`&#x2026;

```lisp
(mapc (lambda (file)
  <<elisp-func>>) '($FILES))
```
-   open it within Emacs;
    
    ```lisp
    (find-file (expand-file-name file "$DIR"))
    ```
-   tangle it;
    
    ```lisp
    (org-babel-tangle)
    ```
-   then close it.
    
    ```lisp
    (kill-buffer)
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
