;;; lsp-isar-caret.el --- Communicate caret position ;;; -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2020 Mathias Fleury
;; URL: https://bitbucket.org/zmaths/isabelle2019-vsce/

;; Keywords: lisp
;; Version: 0
;; Package-Requires: ((emacs "29.1"))

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
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; The position of the caret must be updated whenever it moves. This is achieved by instrumenting
;; `post-command-hook' and sending a message.

;;; Code:

(require 'jsonrpc)
(require 'eglot)

(defvar lsp-isar-caret-last-post-command-position 0
  "Holds the cursor position from the last run of post-command-hooks.")

(defvar lsp-isar-caret--last-buffer nil "Holds the buffer of the last position update.")

(defvar lsp-isar-caret--last-line nil "Holds the line of the last position update.")
(defvar lsp-isar-caret--last-column nil "Holds the char of the last position update.")

(define-inline lsp-isar-caret-update-struct (uri line char focus)
  "Make a Caret_Update object for the given LINE and CHAR.

interface Caret_Update {
    uri;
    line: number;
    character: number;
    focus: boolean
}"
  (inline-quote (list :uri ,uri :line ,line :character ,char :focus ,focus)))

(define-inline lsp-isar-caret-cur-line ()
  (inline-quote (1- (line-number-at-pos))))

(define-inline lsp-isar-caret-cur-column ()
  (inline-quote (- (point) (line-beginning-position))))


(defun lsp-isar-caret--update-position-eglot ()
  "Notify Isabelle about current position if needed.
Test if we have a server connection and caret position has changed"
  (when (eq major-mode 'isar-mode)
    (let ((server (eglot-current-server)))
      (when server
        (let ((buffer (or (buffer-base-buffer) (current-buffer)))
              (line (lsp-isar-caret-cur-line))
              (column (save-restriction (widen) (lsp-isar-caret-cur-column))))
          (unless (and
                   (eq buffer lsp-isar-caret--last-buffer)
                   (eql line lsp-isar-caret--last-line)
                   (eql column lsp-isar-caret--last-column))
            (setq lsp-isar-caret--last-buffer buffer)
            (setq lsp-isar-caret--last-line line)
            (setq lsp-isar-caret--last-column column)
            (let ((uri (eglot-path-to-uri (buffer-file-name buffer))))
              (jsonrpc-notify server "PIDE/caret_update" `(:uri ,uri :line ,line :character ,column :focus 1)))))))))


;; https://stackoverflow.com/questions/26544696/an-emacs-cursor-movement-hook-like-the-javascript-mousemove-event
(defun lsp-isar-caret-activate-caret-update ()
  "Initialize automatic update of caret position."
  (add-hook post-command-hook #'lsp-isar-caret--update-position-eglot)
  (lsp-isar-caret--update-position-eglot))

(provide 'lsp-isar-caret)

;;; lsp-isar-caret.el ends here
