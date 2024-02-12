;;; lsp-isar.el --- Initialise and setup LSP protocol for Isabelle -*- lexical-binding: t -*-


;; Copyright (C) 2018-2020 Mathias Fleury
;; URL: https://bitbucket.org/zmaths/isabelle2019-vsce/

;; Keywords: lisp
;; Version: 0
;; Package-Requires: ((emacs "29.1") (transient "0.1.0"))

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and-or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; blabla

;;; Code:
(require 'eglot)
(require 'transient)

(require 'lsp-isar-caret)
;; (require 'lsp-isar-decorations)
;; (require 'lsp-isar-find-theorems)
(require 'lsp-isar-indent)
;; (require 'lsp-isar-output)
(require 'lsp-isar-parse-args)
;; (require 'lsp-isar-progress)

(defcustom lsp-isar-init-hook nil
  "List of functions to be called after Isabelle has been started."
  :type 'hook
  :group 'isabelle)

(defcustom lsp-isar-indentation t
  "Experimental settings."
  :type 'boolean
  :group 'isabelle)

(defcustom lsp-isar-experimental nil
  "Experimental settings."
  :type 'boolean
  :group 'isabelle)

(defvar lsp-isar-already-initialised nil
  "Indicate if initialised.

Boolean to indicate if we have already initialised progress updates,
the output buffer, and the initial hooks.")


(defcustom lsp-isar-file-name-follow-links (lambda (x) x)
  "Function to replace stuff by other stuff.

A typical example is

   (replace-regexp-in-string
      (regexp-quote \"/mnt/doc/isabelle/afp-2020\")
      \"/home/zmaths/Documents/isabelle/afp-2020\"
      path nil \\='literal)

where the path are replaced by what you need to be
replaced. Remember that Isabelle canonicalize paths
automatically."
  :type 'function
  :group 'isabelle)

(defcustom lsp-isar-file-name-unfollow-links (lambda (x) x)
  "Function to replace canonical paths by relative paths.

A typical example is

   (replace-regexp-in-string
      (regexp-quote \"/mnt/doc/isabelle/afp-2020\")
      \"/home/zmaths/Documents/isabelle/afp-2020\"
      path nil \\='literal)

where the path are replaced by what you need to be
replaced. Remember that Isabelle canonicalize paths
automatically."
  :type 'function
  :group 'isabelle)

(defcustom lsp-isar-use-lsp t
  "Use nil to open files without opening the server.

A potentially easier way to control is to use the option
`--noisabelle' you can pass to Emacs. It has the same effect, but
you can decide at startup what you want."
  :type 'bool
  :group 'isabelle)

(defun lsp-isar-initialise ()
  "Initialise all Isar-related informations."
  (when (equal major-mode 'isar-mode)
    ;; delayed decoration printing
    (lsp-isar-caret-activate-caret-update)
    ;; (lsp-isar-decorations-activate-delayed-printing)
    (unless lsp-isar-already-initialised
      ;; (lsp-isar-output-initialize-output-buffer)
      ;; (lsp-isar-progress-activate-progress-update)
      ;; (lsp-isar-decorations--init-decorations)
      (run-hooks 'lsp-isar-init-hook)
      (setq lsp-isar-already-initialised t))))

(add-hook 'eglot-managed-mode-hook (lambda () (when (eglot-managed-p) (lsp-isar-initialise))))

(defvar lsp-isar--already-split nil
  "Boolean to indicate if we have already split the window.")

(defvar lsp-isar-split-pattern-three-columns 'lsp-isar-split-pattern-three-columns)
(defvar lsp-isar-split-pattern-two-columns 'lsp-isar-split-pattern-two-columns)

(defcustom lsp-isar-split-pattern 'lsp-isar-split-pattern-two-columns
  "Split motif for the columns."
  :type
  '(choice
    (const :tag "Split in two columns" lsp-isar-split-pattern-two-columns)
    (const :tag "Split in three columns (with progress on the right)"
	   lsp-isar-split-pattern-three-columns))
  :group 'isabelle);;

;; taken from
;; https://emacs.stackexchange.com/questions/2189/how-can-i-prevent-a-command-from-using-specific-windows
(defun lsp-isar-toggle-window-dedicated ()
  "Dedicate current window to content.

Control whether or not Emacs is allowed to display another
buffer in current window."
  (let ((window (get-buffer-window (current-buffer))))
    (set-window-dedicated-p window (not (window-dedicated-p window)))))

;; unconditionnaly split the window
(defun lsp-isar-open-output-and-progress-right-two-columns ()
  "Opens the *lsp-isar-output* and *lsp-isar-progress* buffers on the right."
  (interactive)
  (split-window-right)
  (other-window 1)
  (switch-to-buffer "*lsp-isar-state*")
  (lsp-isar-toggle-window-dedicated)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*lsp-isar-output*")
  (lsp-isar-toggle-window-dedicated)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*lsp-isar-progress*")
  (lsp-isar-toggle-window-dedicated)
  (other-window -3))

(defun lsp-isar-open-output-and-progress-right-three-columns ()
  "Opens the *lsp-isar-output* and *lsp-isar-progress* buffers on the right."
  (interactive)
  ;; split first
  (split-window-right)
  (other-window 1)

  ;; split second
  (split-window-right)
  (other-window 1)
  (switch-to-buffer "*lsp-isar-progress*")
  (lsp-isar-toggle-window-dedicated)

  (other-window -1)
  (switch-to-buffer "*lsp-isar-state*")
  (lsp-isar-toggle-window-dedicated)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*lsp-isar-output*")
  (lsp-isar-toggle-window-dedicated)
  (other-window -2))


(defun lsp-isar-open-output-and-progress-right ()
  "Opens the *lsp-isar-output* and *lsp-isar-progress* buffers on the right.

It can be used for example by ``(add-hook \\='lsp-isar-init-hook
\\='lsp-isar-open-output-and-progress-right-spacemacs)''."
  (cond
   ((eq lsp-isar-split-pattern 'lsp-isar-split-pattern-two-columns)
    (lsp-isar-open-output-and-progress-right-two-columns))
   ((eq lsp-isar-split-pattern 'lsp-isar-split-pattern-three-columns)
    (lsp-isar-open-output-and-progress-right-three-columns))
   (t (message "unrecognised motif to split window.  See variable `lsp-isar-split-pattern'"))))

;; split the window 2 seconds later (the timeout is necessary to give
;; enough time to spacemacs to jump to the theory file).
(defun lsp-isar-open-output-and-progress-right-spacemacs ()
  "Split the window with motif defined by `lsp-isar-split-pattern'."
  (run-at-time 2 nil (lambda () (lsp-isar-open-output-and-progress-right))))


(defcustom lsp-isar-path-to-isabelle "/home/zmaths/Documents/isabelle/isabelle2018-vsce"
  "Default path to Isabelle (e.g., /path/to/isabelle/folder)."
  :type 'string
  :group 'isabelle)

(defcustom lsp-vscode-options
  (list
   "-o" "vscode_pide_extensions"
   "-o" "vscode_caret_perspective=10")
  "Isabelle's LSP server options.

Please refer to the documentation of Isabelle for the full set of
options.  In most cases, you should keep the options
`(list \"-o\" \"vscode_pide_extensions\")'.

Set `lsp-isabelle-options' for other options (like importing the AFP)."
  :type '(list string)
  :group 'isabelle)

(defvar lsp-isar--already-defined-client nil
  "Variable testing if the LSP client has already been defined.")


(defcustom lsp-isar-remote-path-to-isabelle
  "isabelle"
  "Default path to Isabelle (e.g., /path/to/isabelle/folder)."
  :type '(string)
  :group 'isabelle)

(defun lsp-full-remote-isabelle-path ()
  "Full remote isabelle command."
  (append
   (list lsp-isar-remote-path-to-isabelle
	 "vscode_server")
   lsp-vscode-options
   lsp-remote-isabelle-options))


(defun lsp-full-isabelle-path ()
  "Calculate the full path and the options for Isabelle."
  (append
   (list (concat lsp-isar-path-to-isabelle "/bin/isabelle")
	 "vscode_server")
   lsp-vscode-options
   lsp-isabelle-options))

(defun lsp-isar-define-client ()
  "Configure LSP client for isar-mode with eglot."
  (add-to-list 'eglot-server-programs `(isar-mode . ,(lsp-full-isabelle-path)))
  ;; TODO add handlers for special events
  )

;;;###autoload
(defun lsp-isar-define-client-and-start ()
  "Setup the LSP client if required and start LSP in the current buffer.

This is the main entry point of the lsp-isar client.  To start the
mode automically, use `(add-hook \\='isar-mode-hook
#\\='lsp-isar-define-client-and-start)'"
  ;; starting lsp
  (when (or (not lsp-isar-use-lsp) lsp-isar-parse-args-noisabelle)
    (message "not starting the server! Set lsp-isar-use-lsp to t for that and do not pass '--noisabelle' as argument to Emacs."))
  (unless (or
           (not lsp-isar-use-lsp)
           lsp-isar-parse-args-noisabelle
           (boundp 'lsp-isar-already-started))
    (set (make-local-variable 'lsp-isar-already-started) t)
    (unless lsp-isar--already-defined-client
      (lsp-isar-define-client)
      (setq lsp-isar--already-defined-client t))
    (eglot-ensure)))

;; although the communication to the LSP server is done using utf-16,
;; we can only use utf-8
(modify-coding-system-alist 'file "\\.thy\\'" 'utf-8)

(defun lsp-isar-activate-indentation ()
  "Activate automatic indentation by default."
  (when lsp-isar-indentation
    (set (make-local-variable 'indent-line-function) 'lsp-isar-indent-line)))

(add-hook 'isar-mode-hook #'lsp-isar-activate-indentation)


(defun lsp-isar-activate-experimental-features ()
  "Activate experimental features.")

(add-hook 'isar-mode-hook #'lsp-isar-activate-experimental-features)



;; https://stackoverflow.com/questions/33442027/how-to-deleteor-kill-the-current-word-in-emacs
(defun lsp-isar-kill-thing-at-point (thing)
  "Kill the `thing-at-point' for the specified kind of THING."
  (let ((bounds (bounds-of-thing-at-point thing)))
    (if bounds
        (kill-region (car bounds) (cdr bounds))
      (error "No %s at point" thing))))

(defun lsp-isar-kill-word-at-point ()
  "Kill the word at point."
  (lsp-isar-kill-thing-at-point 'word))

(defun lsp-isar-insert-sendback (&optional proof-command prover keep-command)
  "Insert proof from PROVER position, keeping the command if KEEP-COMMAND.

Looks at the last sledgehammer result, removes the word
PROOF-COMMAND if pointed at, then inserts the proofs if any.

If there is no proof, the sledgehammer call is not removed and
the transient is re-opened."
  (interactive "P")
  ;;(message "word-at-point= %s %s" (word-at-point) (eq (word-at-point) "sledgehammer"))
  ;; the list is in reverse order (last completion first in the list)
  (let* ((idx (- (length lsp-isar-output-proof-cases-content) prover))
	 (prover idx)
         (sh (nth prover lsp-isar-output-proof-cases-content)))
    ;; (message "%s" lsp-isar-output-proof-cases-content)
    (if (not sh)
	(if (string= proof-command "sledgehammer")
	    (lsp-isar-sledgehammer-interface))
      (if (and (not keep-command) (string= (word-at-point) proof-command))
	  (lsp-isar-kill-word-at-point)
        (end-of-line)
	(insert "\n"))
      (insert sh))))

(defun lsp-isar-insert-sledgehammer-proof (prover keep-sledgehammer)
  "Insert proof by PROVER found in ISAR, keeping the command if KEEP-SLEDGEHAMMER.

See documentation from `lsp-isar-insert-sendback' for more details"
  (interactive "P")
  (lsp-isar-insert-sendback "sledgehammer" prover keep-sledgehammer))


(defun lsp-isar-insert-proof-outline ()
  "Insert proof outline."
  (interactive)
  (end-of-line)
  (let ((begin (point)))
    (lsp-isar-insert-sendback "Isar" 1 nil)
    (if lsp-isar-experimental
	(indent-region begin (point)))))


(defun lsp-isar-insert-cases ()
  "Insert the last seen outline at the beginning of the next line.

This is meant to be used for skeletons as generated by
`proof (induction)' or `proof cases'."
  (interactive)
  (lsp-isar-insert-proof-outline))

(defun lsp-isar-keep-sledgehammer (transient)
  "Find out if the --keep-sledgehammer option is set in TRANSIENT."
  (--if-let (--first (string-prefix-p "--keep-sledgehammer" it)
                     (transient-args transient))
      t
    nil))

(defun lsp-isar-insert-sledgehammer-proof-1 (keep-sledgehammer)
  "Insert 1st proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 1 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-2 (keep-sledgehammer)
  "Insert 2nd proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 2 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-3 (keep-sledgehammer)
  "Insert 3rd proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 3 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-4 (keep-sledgehammer)
  "Insert 4th proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 4 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-5 (keep-sledgehammer)
  "Insert 5th proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 5 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-6 (keep-sledgehammer)
  "Insert 6th proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 6 keep-sledgehammer))

(defun lsp-isar-insert-sledgehammer-proof-7 (keep-sledgehammer)
  "Insert 7th proofs keeping sh command if KEEP-SLEDGEHAMMER."
  (interactive
   (list (lsp-isar-keep-sledgehammer 'lsp-isar-sledgehammer-interface)))
  (lsp-isar-insert-sledgehammer-proof 7 keep-sledgehammer))

(defun lsp-isar-delete-sledgehammer-call ()
  "Insert veriT proofs."
  (interactive)
  (if (string= (word-at-point) "sledgehammer")
      (lsp-isar-kill-word-at-point)))


(transient-define-prefix lsp-isar-sledgehammer-interface ()
  "Interface to insert sledgehammer command in theory.

The options `--isar' is set automatically set if there only one
choice for the given prover."

  ["Options"
   ("k" "Keep sledgehammer call if cursor is on it" "--keep-sledgehammer")]
  ["Insert calls"
   ("1" "proof |1|" lsp-isar-insert-sledgehammer-proof-1)
   ("2" "proof |2|" lsp-isar-insert-sledgehammer-proof-2)
   ("3" "proof |3|" lsp-isar-insert-sledgehammer-proof-3)
   ("4" "proof |4|" lsp-isar-insert-sledgehammer-proof-4)
   ("5" "proof |5|" lsp-isar-insert-sledgehammer-proof-5)
   ("6" "proof |6|" lsp-isar-insert-sledgehammer-proof-6)
   ("7" "proof |7|" lsp-isar-insert-sledgehammer-proof-7)
   ("d" "delete sledgehammer call" lsp-isar-delete-sledgehammer-call)])


(define-key isar-mode-map (kbd "C-x s") 'lsp-isar-sledgehammer)


(defun lsp-isar-insert-command (command)
  "Insert COMMAND at cursor position.

If there is no whitespace at cursor position, a space is inserted before COMMAND"
  (interactive)
  (unless (string= (word-at-point) command)
    ;; special case for word|
    (when (and (word-at-point) (not (thing-at-point 'whitespace)))
      (forward-word))
    (backward-char)
    (let ((is-space (thing-at-point 'whitespace)))
      (forward-char)
      (unless is-space
        (insert " ")))
    (insert command)))


(defun lsp-isar-insert-sledgehammer ()
  "Insert sledgehammer.

If there is no whitespace at the current point, we insert a space before
the sledgehammer command."
  (interactive)
  (lsp-isar-insert-command "sledgehammer"))


(defun lsp-isar-insert-sledgehammer-and-call ()
  "Insert sledgehammer and open the interface.

If there is no whitespace at the current point, we insert a space before
the sledgehammer command."
  (interactive)
  (lsp-isar-insert-sledgehammer)
  (lsp-isar-sledgehammer-interface))

(define-key isar-mode-map (kbd "C-c C-s") 'lsp-isar-insert-sledgehammer-and-call)



(defun lsp-isar-keep-try0 (transient)
  "Find out if the --keep-try0 option is set in TRANSIENT."
  (--if-let (--first (string-prefix-p "--keep-try0" it)
                     (transient-args transient))
      t
    nil))
(defun lsp-isar-insert-try-proof (prover keep-try)
  "Insert proof by PROVER found in ISAR, keeping the command if KEEP-TRY0.

See documentation from `lsp-isar-insert-sendback' for more details"
  (interactive "P")
  (lsp-isar-insert-sendback "try0" prover keep-try))

(defun lsp-isar-insert-try-proof-1 (keep-try0)
  "Insert 1st proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 1 keep-try0))

(defun lsp-isar-insert-try-proof-2 (keep-try0)
  "Insert 2nd proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 2 keep-try0))

(defun lsp-isar-insert-try-proof-3 (keep-try0)
  "Insert 3rd proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 3 keep-try0))

(defun lsp-isar-insert-try-proof-4 (keep-try0)
  "Insert 4th proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 4 keep-try0))

(defun lsp-isar-insert-try-proof-5 (keep-try0)
  "Insert 5th proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 5 keep-try0))

(defun lsp-isar-insert-try-proof-6 (keep-try0)
  "Insert 6th proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 6 keep-try0))

(defun lsp-isar-insert-try-proof-7 (keep-try0)
  "Insert 7th proofs keeping sh command if KEEP-TRY0."
  (interactive
   (list (lsp-isar-keep-try0 'lsp-isar-try-interface)))
  (lsp-isar-insert-try-proof 7 keep-try0))

(defun lsp-isar-delete-try-call ()
  "Insert veriT proofs."
  (interactive)
  (if (string= (word-at-point) "try0")
      (lsp-isar-kill-word-at-point)))


(transient-define-prefix lsp-isar-try-interface ()
  "Interface to insert try0 command in theory.

The options `--isar' is set automatically set if there only one
choice for the given prover."

  ["Options"
   ("k" "Keep try0 call if cursor is on it" "--keep-try0")]
  ["Insert calls"
   ("1" "proof |1|" lsp-isar-insert-try-proof-1)
   ("2" "proof |2|" lsp-isar-insert-try-proof-2)
   ("3" "proof |3|" lsp-isar-insert-try-proof-3)
   ("4" "proof |4|" lsp-isar-insert-try-proof-4)
   ("5" "proof |5|" lsp-isar-insert-try-proof-5)
   ("6" "proof |6|" lsp-isar-insert-try-proof-6)
   ("7" "proof |7|" lsp-isar-insert-try-proof-7)
   ("d" "delete try0 call" lsp-isar-delete-try-call)])


(defun lsp-isar-insert-try ()
  "Insert try.

If there is no whitespace at the current point, we insert a space before
the try command."
  (interactive)
  (lsp-isar-insert-command "try0"))


(defun lsp-isar-insert-try-and-call ()
  "Insert try and open the interface.

If there is no whitespace at the current point, we insert a space before
the try command."
  (interactive)
  (lsp-isar-insert-try)
  (lsp-isar-try-interface))

(define-key isar-mode-map (kbd "C-c t") 'lsp-isar-insert-try-and-call)

(defun lsp-isar-insert-simp ()
  "Insert \"by simp\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by simp"))

(define-key isar-mode-map (kbd "C-c C-b C-s") 'lsp-isar-insert-simp)

(defun lsp-isar-insert-auto ()
  "Insert \"by auto\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by auto"))

(define-key isar-mode-map (kbd "C-c C-b C-a") 'lsp-isar-insert-simp)

(defun lsp-isar-insert-blast ()
  "Insert \"by blast\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by blast"))

(define-key isar-mode-map (kbd "C-c C-b C-b") 'lsp-isar-insert-simp)

(defun lsp-isar-insert-metis ()
  "Insert \"by metis\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by metis"))

(define-key isar-mode-map (kbd "C-c C-b C-m") 'lsp-isar-insert-metis)

(defun lsp-isar-insert-argo ()
  "Insert \"by argo\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by argo"))

(define-key isar-mode-map (kbd "C-c C-b C-r") 'lsp-isar-insert-argo)

(defun lsp-isar-insert-linarith ()
  "Insert \"by linarith\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by linarith"))

(define-key isar-mode-map (kbd "C-c C-b C-l") 'lsp-isar-insert-linarith)

(defun lsp-isar-insert-algebra ()
  "Insert \"by algebra\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by algebra"))

(define-key isar-mode-map (kbd "C-c C-b C-g") 'lsp-isar-insert-algebra)

(defun lsp-isar-insert-presburger ()
  "Insert \"by presburger\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by presburger"))

(define-key isar-mode-map (kbd "C-c C-b C-p") 'lsp-isar-insert-presburger)

(defun lsp-isar-insert-fast ()
  "Insert \"by fast\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by fast"))

(define-key isar-mode-map (kbd "C-c C-b C-f C-a") 'lsp-isar-insert-fast)

(defun lsp-isar-insert-fastforce ()
  "Insert \"by fastforce\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by fastforce"))

(define-key isar-mode-map (kbd "C-c C-b C-f C-f") 'lsp-isar-insert-fastforce)

(defun lsp-isar-insert-force ()
  "Insert \"by force\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by force"))

(define-key isar-mode-map (kbd "C-c C-b C-f C-o") 'lsp-isar-insert-force)

(defun lsp-isar-insert-meson ()
  "Insert \"by meson\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by meson"))

(define-key isar-mode-map (kbd "C-c C-b C-e") 'lsp-isar-insert-meson)

(defun lsp-isar-insert-satx ()
  "Insert \"by satx\" at cursor position with whitespace in front if necessary."
  (interactive)
  (lsp-isar-insert-command "by satx"))

(define-key isar-mode-map (kbd "C-c C-b C-s") 'lsp-isar-insert-satx)

;; This needs to be done at the very beginning!
;; (defun lsp-isar-make-buffer-name-absolute ()
;;   "Replace the current path by the full buffer name."
;;   (setq-local lsp-buffer-uri (lsp--path-to-uri (file-truename (buffer-file-name)))))

;; (add-hook 'lsp-before-initialize-hook #'lsp-isar-make-buffer-name-absolute)

(provide 'lsp-isar)

;;; lsp-isar.el ends here
