;; ─────────────────────────────────── Set up 'package' ───────────────────────────────────
(require 'package)

;; Add melpa to package archives.
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)

;; Load and activate emacs packages. Do this first so that the packages are loaded before
;; you start trying to modify them.  This also sets the load path.
(package-initialize)

;; Install 'use-package' if it is not installed.
(when (not (package-installed-p 'use-package))
  (package-refresh-contents)
  (package-install 'use-package))



;; ───────────────────────────────── Use better defaults ────────────────────────────────
(setq-default
 ;; Don't use the compiled code if its the older package.
 load-prefer-newer t

 ;; Do not show the startup message.
 inhibit-startup-message t

 ;; Do not put 'customize' config in init.el; give it another file.
 custom-file "~/.emacs.d/custom-file.el"

 ;; 72 is too less for the fontsize that I use.
 fill-column 90

 ;; Use your name in the frame title. :)
 frame-title-format (format "%s's Emacs" (capitalize user-login-name))

 ;; Do not create lockfiles.
 create-lockfiles nil

 ;; Don't use hard tabs
 indent-tabs-mode nil

 ;; Emacs can automatically create backup files. This tells Emacs to put all backups in
 ;; ~/.emacs.d/backups. More info:
 ;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Backup-Files.html
 backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))

 ;; Do not autosave.
 auto-save-default nil

 ;; Allow commands to be run on minibuffers.
 enable-recursive-minibuffers t)

;; Change all yes/no questions to y/n type
(fset 'yes-or-no-p 'y-or-n-p)

;; Make the command key behave as 'meta'
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (setq mac-right-command-modifier 'hyper))

;; `C-x o' is a 2 step key binding. `M-o' is much easier.
(global-set-key (kbd "M-o") 'other-window)

;; Unbind `save-buffers-kill-terminal` to avoid accidentally quiting Emacs.
;; (global-unset-key (kbd "C-x C-c"))

;; Delete whitespace just when a file is saved.
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Enable narrowing commands.
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)

(global-set-key (kbd "H-d") 'narrow-to-defun)
(global-set-key (kbd "H-t") 'narrow-to-defun)
(global-set-key (kbd "H-w") 'widen)

;; Display column number in mode line.
(column-number-mode t)

;; Automatically update buffers if file content on the disk has changed.
(global-auto-revert-mode t)


;; ─────────────────────────── Disable unnecessary UI elements ──────────────────────────
(progn

  ;; Do not show tool bar.
  (when (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))

  ;; Do not show scroll bar.
  (when (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

  ;; Highlight line on point.
  (global-hl-line-mode t))



;; ───────────────────────── Better interaction with X clipboard ────────────────────────
(setq-default
 ;; Makes killing/yanking interact with the clipboard.
 x-select-enable-clipboard t

 ;; To understand why this is done, read `X11 Copy & Paste to/from Emacs' section here:
 ;; https://www.emacswiki.org/emacs/CopyAndPaste.
 x-select-enable-primary t

 ;; Save clipboard strings into kill ring before replacing them. When
 ;; one selects something in another program to paste it into Emacs, but
 ;; kills something in Emacs before actually pasting it, this selection
 ;; is gone unless this variable is non-nil.
 save-interprogram-paste-before-kill t

 ;; Shows all options when running apropos. For more info,
 ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Apropos.html.
 apropos-do-all t

 ;; Mouse yank commands yank at point instead of at click.
 mouse-yank-at-point t)


;; ──────────────────────── Added functionality (Generic usecases) ────────────────────────

;; Set a directory for temporary/state related files.
(defvar dotfiles-dirname
  (file-name-directory (or load-file-name
                           (buffer-file-name)))
  "The directory where this code is running from. Ideally, this will be ~/.emacs.d.")


(load (concat dotfiles-dirname "defuns.el"))


(defun toggle-comment-on-line ()
  "Comment or uncomment current line."
  (interactive)
  (comment-or-uncomment-region (line-beginning-position) (line-end-position)))

(global-set-key (kbd "C-;") 'toggle-comment-on-line)

(defun comment-pretty ()
  "Insert a comment with '─' (C-x 8 RET BOX DRAWINGS LIGHT HORIZONTAL) on each side."
  (interactive)
  (let* ((comment-char "─")
         (comment (read-from-minibuffer "Comment: "))
         (comment-length (length comment))
         (current-column-pos (current-column))
         (space-on-each-side (/ (- fill-column
                                   current-column-pos
                                   comment-length
                                   (length comment-start)
                                   ;; Single space on each side of comment
                                   (if (> comment-length 0) 2 0)
                                   ;; Single space after comment syntax sting
                                   1)
                                2)))
    (if (< space-on-each-side 2)
        (message "Comment string is too big to fit in one line")
      (progn
        (insert comment-start)
        (when (equal comment-start ";")
          (insert comment-start))
        (insert " ")
        (dotimes (_ space-on-each-side) (insert comment-char))
        (when (> comment-length 0) (insert " "))
        (insert comment)
        (when (> comment-length 0) (insert " "))
        (dotimes (_ (if (= (% comment-length 2) 0)
                        space-on-each-side
                      (- space-on-each-side 1)))
          (insert comment-char))))))

(global-set-key (kbd "C-c ;") 'comment-pretty)



;; Start Emacsserver so that emacsclient can be used
(server-start)




;; ───────────────────── Additional packages and their configurations ─────────────────────
(require 'use-package)

;; Add `:doc' support for use-package so that we can use it like what a doc-strings is for
;; functions.
(eval-and-compile
  (add-to-list 'use-package-keywords :doc t)
  (defun use-package-handler/:doc (name-symbol _keyword _docstring rest state)
    "An identity handler for :doc.
     Currently, the value for this keyword is being ignored.
     This is done just to pass the compilation when :doc is included
     Argument NAME-SYMBOL is the first argument to `use-package' in a declaration.
     Argument KEYWORD here is simply :doc.
     Argument DOCSTRING is the value supplied for :doc keyword.
     Argument REST is the list of rest of the  keywords.
     Argument STATE is maintained by `use-package' as it processes symbols."

    ;; just process the next keywords
    (use-package-process-keywords name-symbol rest state)))


;; ─────────────────────────────────── Generic packages ───────────────────────────────────
(use-package delight
  :ensure t
  :delight)

(use-package uniquify
  :doc "Naming convention for files with same names"
  :config
  (setq uniquify-buffer-name-style 'forward)
  :delight)

(use-package recentf
  :doc "Recent buffers in a new Emacs session"
  :config
  (setq recentf-auto-cleanup 'never
        recentf-max-saved-items 1000
        recentf-save-file (concat user-emacs-directory ".recentf"))
  (recentf-mode t)
  :delight)

(use-package ibuffer
  :doc "Better buffer management"
  :bind ("C-x C-b" . ibuffer)
  :delight)

(use-package projectile
  :doc "Project navigation"
  :ensure t
  :config
  ;; Use it everywhere
  (projectile-mode t)
  :bind ("C-x f" . projectile-find-file)
  :delight)

(use-package magit
  :doc "Git integration for Emacs"
  :ensure t
  :bind ("C-x g" . magit-status)
  :delight)

(use-package ace-jump-mode
  :doc "Jump around the visible buffer using 'Head Chars'"
  :ensure t
  :bind ("C-." . ace-jump-mode)
  :delight)

(use-package dumb-jump
  :doc "Dumb ag version of M-."
  :ensure t
  :bind ("C-M-." . dumb-jump-go)
  :delight)

(use-package which-key
  :doc "Prompt the next possible key bindings after a short wait"
  :ensure t
  :config
  (which-key-mode t)
  :delight)


(use-package exec-path-from-shell
  :doc "MacOS does not start a shell at login. This makes sure
          that the env variable of shell and GUI Emacs look the
          same."
  :ensure t
  :if (eq system-type 'darwin)
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize))
  :delight)

(use-package helm
  :ensure t
  :bind (("C-x c r" . nil)
         ("C-x c r b" . helm-filtered-bookmarks)
         ("C-x c r r" . helm-regexp)
         ("C-x b" . helm-buffers-list)
         ("M-y" . helm-show-kill-ring)
         ("C-x c SPC" . helm-all-mark-rings)
         ("C-h SPC" . helm-all-mark-rings)
         ("C-x c r i" . helm-register)
         ("M-i" . helm-imenu)
         ("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("M-s M-s" . helm-occur))
  :bind (:map helm-map
	      ("M-i" . helm-previous-line)
	      ("M-k" . helm-next-line)
	      ("M-I" . helm-previous-page)
	      ("M-K" . helm-next-page)
	      ("M-h" . helm-beginning-of-buffer)
	      ("M-H" . helm-end-of-buffer))
  :config (progn
            (setq helm-buffers-fuzzy-matching t
                  helm-recentf-fuzzy-match t
                  helm-apropos-fuzzy-match t
                  helm-M-x-fuzzy-match t
                  helm-imenu-fuzzy-match t
                  helm-mode-fuzzy-match t
                  helm-completion-in-region-fuzzy-match t
                  helm-candidate-number-limit 100
                  helm-split-window-default-side 'below
                  helm-full-frame nil)
            (helm-mode 1))
  :delight)


(use-package helm-descbinds
  :ensure t
  :bind ("C-h b" . helm-descbinds)
  :config (progn (helm-descbinds-mode))
  :delight)


(use-package helm-ag
  :ensure t
  :bind (("C-x c g a" . helm-do-ag-project-root)
         ("C-x c g s" . helm-do-ag)
         ("C-x c g g" . helm-do-grep-ag))
  :config (progn (setq helm-ag-insert-at-point 'symbol
                       helm-ag-fuzzy-match t
                       helm-truncate-lines t
                       helm-ag-use-agignore t))
  :delight)


(use-package helm-projectile
  :ensure t
  :bind (("C-c p" . projectile-command-map))
  :config (progn (require 'helm-projectile)
                 (projectile-mode)
                 (setq projectile-completion-system 'helm
                       projectile-switch-project-action 'helm-projectile
                       projectile-enable-caching t
                       projectile-mode-line '(:eval (if (file-remote-p default-directory)
                                                        " "
                                                      (format " Ptl[%s]"
                                                              (projectile-project-name)))))
                 (helm-projectile-on))
  :delight)



(use-package ivy
  :doc "A generic completion mechanism"
  :ensure t
  :config
  (ivy-mode t)
  (setq ivy-use-virtual-buffers t

        ;; Display index and count both.
        ivy-count-format "(%d/%d) "

        ;; By default, all ivy prompts start with `^'. Disable that.
        ivy-initial-inputs-alist nil)

  :bind (("C-x b" . ivy-switch-buffer)
         ("C-x B" . ivy-switch-buffer-other-window))
  :delight)

(use-package ivy-rich
  :doc "Have additional information in empty space of ivy buffers."
  :disabled t
  :ensure t
  :custom
  (ivy-rich-path-style 'abbreviate)
  :config
  (setcdr (assq t ivy-format-functions-alist)
          #'ivy-format-function-line)
  (ivy-rich-mode 1)
  :delight)

(use-package git-gutter
  :doc "Shows modified lines"
  :ensure t
  :config
  (setq git-gutter:modified-sign "|")
  (setq git-gutter:added-sign "|")
  (setq git-gutter:deleted-sign "|")
  (set-face-foreground 'git-gutter:modified "grey")
  (set-face-foreground 'git-gutter:added "green")
  (set-face-foreground 'git-gutter:deleted "red")
  (global-git-gutter-mode t)
  :delight)

(use-package git-timemachine
  :doc "Go through git history in a file"
  :ensure t
  :delight)

(use-package region-bindings-mode
  :doc "Define bindings only when a region is selected."
  :ensure t
  :config
  (region-bindings-mode-enable)
  :delight)

(use-package multiple-cursors
  :doc "A minor mode for editing with multiple cursors"
  :ensure t
  :config
  (setq mc/always-run-for-all t)
  :bind
  ;; Use multiple cursor bindings only when a region is active
  (:map region-bindings-mode-map
        ("C->" . mc/mark-next-like-this)
        ("C-<" . mc/mark-previous-like-this)
        ("C-c a" . mc/mark-all-like-this)
        ("C-c h" . mc-hide-unmatched-lines-mode)
        ("C-c l" . mc/edit-lines))
  :delight)

(use-package async
  :doc "Simple library for asynchronous processing in Emacs")

(use-package define-word
  :doc "Dictionary in Emacs."
  :ensure t
  :bind ("C-c w" . define-word-at-point)
  :delight)


(use-package diminish
  :doc "Hide minor modes from mode line"
  :ensure t
  :delight)


(use-package flyspell
  :config

  ;; Flyspell should be able to learn a word without the
  ;; `flyspell-correct-word-before-point` pop up.
  ;; Refer:
  ;; https://stackoverflow.com/questions/22107182/in-emacs-flyspell-mode-how-to-add-new-word-to-dictionary
  (defun flyspell-learn-word-at-point ()
    "Add word at point to list of correct words."
    (interactive)
    (let ((current-location (point))
          (word (flyspell-get-word)))
      (when (consp word)
        (flyspell-do-correct 'save nil
                             (car word) current-location
                             (cadr word) (caddr word)
                             current-location))))

  ;; This color is specific to `nord` theme.
  (set-face-attribute 'flyspell-incorrect nil :underline '(:style line :color "#bf616a"))
  (set-face-attribute 'flyspell-duplicate nil :underline '(:style line :color "#bf616a"))

  :bind ("H-l" . flyspell-learn-word-at-point))


;; ───────────────────────────────────── Code editing ─────────────────────────────────────

(use-package company
  :doc "COMplete ANYthing"
  :ensure t
  :bind (:map
         global-map
         ("TAB" . company-complete-common-or-cycle)
         ;; Use hippie expand as secondary auto complete. It is useful as it is
         ;; 'buffer-content' aware (it uses all buffers for that).
         ("M-/" . hippie-expand)
         :map company-active-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous))
  :config
  (setq company-idle-delay 0.1)
  (global-company-mode t)

  ;; Configure hippie expand as well.
  (setq hippie-expand-try-functions-list
        '(try-expand-dabbrev
          try-expand-dabbrev-all-buffers
          try-expand-dabbrev-from-kill
          try-complete-lisp-symbol-partially
          try-complete-lisp-symbol))

  :delight)



(use-package paredit
  :doc "Better handling of paranthesis when writing Lisp"
  :ensure t
  :init
  (add-hook 'clojure-mode-hook #'enable-paredit-mode)
  (add-hook 'cider-repl-mode-hook #'enable-paredit-mode)
  (add-hook 'emacs-lisp-mode-hook #'enable-paredit-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
  (add-hook 'ielm-mode-hook #'enable-paredit-mode)
  (add-hook 'lisp-mode-hook #'enable-paredit-mode)
  (add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
  (add-hook 'scheme-mode-hook #'enable-paredit-mode)
  :config
  (show-paren-mode t)
  :bind (("M-[" . paredit-wrap-square)
         ("M-{" . paredit-wrap-curly))
  :delight)


(use-package paxedit
  :ensure t
  :init (add-hook 'clojure-mode-hook 'paxedit-mode)
        (add-hook 'emacs-lisp-mode-hook 'paxedit-mode)
  :bind (("M-<right>" . paxedit-transpose-forward)
         ("M-<left>". paxedit-transpose-backward)
         ("M-<up>" . paxedit-backward-up)
         ("M-<down>" . paxedit-backward-end)
         ("M-b" . paxedit-previous-symbol)
         ("M-f" . paxedit-next-symbol)
         ("C-%" . paxedit-copy)
         ("C-&" . paxedit-kill)
         ("C-*" . paxedit-delete)
         ("C-^" . paxedit-sexp-raise)
         ("M-u" . paxedit-symbol-change-case)
         ("C-@" . paxedit-symbol-copy)
         ("C-#" . paxedit-symbol-kill))
  :delight)


(use-package rainbow-delimiters
  :doc "Colorful paranthesis matching"
  :disabled t ;; This is not really needed when you use paredit
  :ensure t
  :config
  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
  :delight)

(use-package highlight-symbol
  :doc "Highlight and jump to symbols"
  :ensure t
  :config
  (set-face-background 'highlight-symbol-face (face-background 'highlight))
  (setq highlight-symbol-idle-delay 0.5)
  (add-hook 'prog-mode-hook 'highlight-symbol-mode)
  :bind (("M-n" . highlight-symbol-next)
         ("M-p" . highlight-symbol-prev))
  :delight)

(use-package yasnippet
  :ensure t
  :disabled t ;; I'm not using this at the moment.
  :config
  (yas-global-mode t)
  (add-to-list 'hippie-expand-try-functions-list
               'yas-hippie-try-expand)
  :delight)


;; ──────────────────────────────── Programming languages ───────────────────────────────
(use-package clojure-mode
  :doc "A major mode for editing Clojure code"
  :ensure t
  :config
  ;; This is useful for working with camel-case tokens, like names of
  ;; Java classes (e.g. JavaClassName)
  (add-hook 'clojure-mode-hook #'subword-mode)

  ;; Show 'ƒ' instead of 'fn' in clojure mode
  (defun prettify-fns ()
    (font-lock-add-keywords
     nil `(("(\\(fn\\)[\[[:space:]]"
            (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                      "ƒ")
                      nil))))))
  (add-hook 'clojure-mode-hook 'prettify-fns)
  (add-hook 'cider-repl-mode-hook 'prettify-fns)

  ;; Show lambda instead of '#' in '#(...)'
  (defun prettify-anonymous-fns ()
    (font-lock-add-keywords
     nil `(("\\(#\\)("
            (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                      ,(make-char 'greek-iso8859-7 107))
                      nil))))))
  (add-hook 'clojure-mode-hook 'prettify-anonymous-fns)
  (add-hook 'cider-repl-mode-hook 'prettify-anonymous-fns)

  ;; Show '∈' instead of '#' in '#{}' (sets)
  (defun prettify-sets ()
    (font-lock-add-keywords
     nil `(("\\(#\\){"
            (0 (progn (compose-region (match-beginning 1) (match-end 1)
                                      "∈")
                      nil))))))
  (add-hook 'clojure-mode-hook 'prettify-sets)
  (add-hook 'cider-repl-mode-hook 'prettify-sets)
  :delight)

(use-package clojure-mode-extra-font-locking
  :doc "Extra syntax highlighting for clojure"
  :ensure t
  :delight)

(use-package cider
  :doc "Integration with a Clojure REPL cider"
  :ensure t

  :init
  ;; Enable minibuffer documentation
  (add-hook 'cider-mode-hook 'eldoc-mode)

  :config
  ;; Go right to the REPL buffer when it's finished connecting
  (setq cider-repl-pop-to-buffer-on-connect t)

  ;; When there's a cider error, show its buffer and switch to it
  (setq cider-show-error-buffer t)
  (setq cider-auto-select-error-buffer t)

  ;; Where to store the cider history.
  (setq cider-repl-history-file "~/.emacs.d/cider-history")

  ;; Wrap when navigating history.
  (setq cider-repl-wrap-history t)

  ;; Attempt to jump at the symbol under the point without having to press RET
  (setq cider-prompt-for-symbol nil)

  ;; Always pretty print
  (setq cider-repl-use-pretty-printing t)

  ;; Log client-server messaging in *nrepl-messages* buffer
  (setq nrepl-log-messages nil)

  ;; ;; REPL should expect input on the next line + unnecessary palm trees!
  ;; (defun cider-repl-prompt-custom (namespace)
  ;;   "Return a prompt string that mentions NAMESPACE."
  ;;   (format "🌴 %s 🌴 \n" namespace))

  ;; (setq cider-repl-prompt-function 'cider-repl-prompt-custom)

  :bind (:map
         cider-mode-map
         ("H-t" . cider-test-run-test)
         ("H-n" . cider-test-run-ns-tests)
         :map
         cider-repl-mode-map
         ("C-c M-o" . cider-repl-clear-buffer))
  :delight)

(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode)

  ;; Do not display errors on left fringe.
  (setq flycheck-indication-mode nil)
  :delight)

(use-package flycheck-joker
  :after clojure-mode
  :ensure t
  :delight)

(use-package flycheck-clj-kondo
  :ensure t
  :after clojure-mode
  :config
  (dolist (checkers '((clj-kondo-clj . clojure-joker)
                      (clj-kondo-cljs . clojurescript-joker)
                      (clj-kondo-cljc . clojure-joker)
                      (clj-kondo-edn . edn-joker)))
    (flycheck-add-next-checker (car checkers) (cons 'error (cdr checkers))))
  :delight)

(use-package clj-refactor
  :disabled t
  :ensure t
  :preface
  (defun clean-all-modified-ns ()
    "Cleans all the modified namespaces. The idea is to use this
    before commiting, so that all the namespaces that you modify are
    cleaned! :)"
    (interactive)
    (let ((extension ".clj")
          ;; `shell-command-to-string` contains a "\n" at its end. `butlast` is used to
          ;; get rid of the last empty string returned by `split-string`.
          (modified-files
           (butlast
            (split-string
             (shell-command-to-string
              "git diff --name-only && git diff --name-only --staged")
             "\n"))))
      (if (= (length modified-files) 0)
          (message "No files have changed.")
        (progn
          (dolist (file modified-files)
            (when (string-equal (substring file (- (length file) (length extension)))
                                extension)
              (when (not (string-equal (first (last (split-string file "/")))
                                       "project.clj"))
                (with-current-buffer (find-file-noselect (concat (cljr--project-dir) file))
                  (cljr--clean-ns)
                  (save-buffer)))))
          (message "Namespaces cleaned! :)")))))

  (defun my-clojure-mode-hook ()
    (clj-refactor-mode 1)
    (yas-minor-mode 1) ;; for adding require/use/import statements
    ;; This choice of keybinding leaves cider-macroexpand-1 unbound
    (cljr-add-keybindings-with-prefix "C-c C-m"))
  :config
  (add-hook 'clojure-mode-hook #'my-clojure-mode-hook)

  :delight)

(use-package eldoc
  :doc "Easily accessible documentation for Elisp"
  :config
  (global-eldoc-mode t)
  :delight)



;; ──────────────────────────────────── Custom config ───────────────────────────────────

(setq ring-bell-function 'ignore)
(global-set-key (kbd "C-a") 'back-to-indentation-or-beginning-of-line)
(global-set-key (kbd "C-7") 'comment-or-uncomment-current-line-or-region)
(global-set-key (kbd "C-6") 'linum-mode)
(global-set-key (kbd "C-v") 'scroll-up-five)
(global-set-key (kbd "M-O") 'mode-line-other-buffer)
(global-set-key (kbd "C-j") 'newline-and-indent)
(global-set-key (kbd "M-g") 'goto-line)
(global-set-key (kbd "M-n") 'open-line-below)
(global-set-key (kbd "M-j") 'join-line-or-lines-in-region)
(global-set-key (kbd "M-p") 'open-line-above)
(global-set-key (kbd "M-+") 'text-scale-increase)
(global-set-key (kbd "M-_") 'text-scale-decrease)
(global-set-key (kbd "M-v") 'scroll-down-five)
(global-set-key (kbd "M-k") 'kill-this-buffer)
(global-set-key (kbd "M-o") 'other-window)
(global-set-key (kbd "C-c s") 'swap-windows)
(global-set-key (kbd "C-c r") 'rename-buffer-and-file)



;; ──────────────────────────────────── Look and feel ───────────────────────────────────
(use-package monokai-alt-theme
  :doc "Just another theme"
  :disabled t
  :ensure t
  :config
  (load-theme 'monokai-alt t)
  ;; The cursor color in this theme is very confusing.
  ;; Change it to green
  (set-cursor-color "#9ce22e")
  ;; Show (line,column) in mode-line
  (column-number-mode t)
  ;; Customize theme
  (custom-theme-set-faces
   'user ;; `user' refers to user settings applied via Customize.
   '(font-lock-comment-face ((t (:foreground "tan3"))))
   '(font-lock-doc-face ((t (:foreground "tan3"))))
   '(mode-line ((t (:background "#9ce22e"
                                :foreground "black"
                                :box (:line-width 3 :color "#9ce22e")
                                :weight normal))))
   '(mode-line-buffer-id ((t (:foreground "black" :weight bold))))
   '(mode-line-inactive ((t (:background "#9ce22e"
                                         :foreground "grey50"
                                         :box (:line-width 3 :color "#9ce22e")
                                         :weight normal))))
   '(org-done ((t (:foreground "chartreuse1" :weight bold))))
   '(org-level-1 ((t (:foreground "RoyalBlue1" :weight bold))))
   '(org-tag ((t (:foreground "#9ce22e" :weight bold)))))
  (custom-set-faces
   ;; custom-set-faces was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   '(font-lock-comment-face ((((class color) (min-colors 89))
                              (:foreground "#b2b2b2" :slant italic))))
   '(font-lock-doc-face ((((class color) (min-colors 89))
                          (:foreground "#cc0000"))))
   '(mode-line ((((class color) (min-colors 89))
                 (:box nil :background "#5fafd7" :foreground "#ffffff"))))
   '(mode-line-buffer-id ((((class color) (min-colors 89))
                           (:box nil :foreground "#3a3a3a" :background nil :bold t))))
   '(mode-line-inactive ((((class color) (min-colors 89))
                          (:box nil :background "#dadada" :foreground "#9e9e9e"))))
   '(org-done ((((class color) (min-colors 89))
                (:bold t :weight bold :foreground "#008700" :background "#d7ff87"
                       :box (:line-width 1 :style none)))))
   '(org-level-1 ((((class color) (min-colors 89)) (:bold t :foreground "#5fafd7"))))
   '(org-tag ((((class color) (min-colors 89))
               (:background "#9e9e9e" :foreground "#ffffff" :bold t :weight bold)))))
  :delight)

(use-package ewal-spacemacs-themes
  :disabled t
  :ensure t
  :config
  (setq-default spacemacs-theme-comment-bg nil
                spacemacs-theme-comment-italic t)
  (load-theme 'spacemacs-dark t)
  :delight)

(use-package nord-theme
  :ensure t
  :config
  (load-theme 'nord t)

  (set-face-attribute 'flycheck-error nil :underline '(:style line :color "#bf616a"))
  (set-face-attribute 'flycheck-warning nil :underline '(:style line :color "#ebcb8b"))
  :delight)

(use-package powerline
  :doc "Better mode line"
  :ensure t
  :config
  (powerline-center-theme)
  :delight)

(use-package "faces"
  :config
  (set-face-attribute 'default nil :height 140)

  ;; Use the 'Fira Code' if available
  (when (not (eq system-type 'windows-nt))
    (when (member "Fira Code" (font-family-list))

      ;; Fira code legatures
      (let ((alist '((33 . ".\\(?:\\(?:==\\|!!\\)\\|[!=]\\)")
                     (35 . ".\\(?:###\\|##\\|_(\\|[#(?[_{]\\)")
                     (36 . ".\\(?:>\\)")
                     (37 . ".\\(?:\\(?:%%\\)\\|%\\)")
                     (38 . ".\\(?:\\(?:&&\\)\\|&\\)")
                     ;; (42 . ".\\(?:\\(?:\\*\\*/\\)\\|\\(?:\\*[*/]\\)\\|[*/>]\\)")
                     (43 . ".\\(?:\\(?:\\+\\+\\)\\|[+>]\\)")
                     ;; Causes "error in process filter: Attempt to shape unibyte text".
                     (45 . ".\\(?:\\(?:-[>-]\\|<<\\|>>\\)\\|[<>}~-]\\)")
                     ;; Fira code page said that this causes an error in Mojave.
                     ;; (46 . ".\\(?:\\(?:\\.[.<]\\)\\|[.=-]\\)")
                     (47 . ".\\(?:\\(?:\\*\\*\\|//\\|==\\)\\|[*/=>]\\)")
                     (48 . ".\\(?:x[a-zA-Z]\\)")
                     ;; Grouping ';' and ':' in groups of 3 causes occur to break. Disable it.
                     ;; (58 . ".\\(?:::\\|[:=]\\)")
                     ;; (59 . ".\\(?:;;\\|;\\)")
                     (60 . ".\\(?:\\(?:!--\\)\\|\\(?:~~\\|->\\|\\$>\\|\\*>\\|\\+>\\|--\\|<[<=-]\\|=[<=>]\\||>\\)\\|[*$+~/<=>|-]\\)")
                     ;; (61 . ".\\(?:\\(?:/=\\|:=\\|<<\\|=[=>]\\|>>\\)\\|[<=>~]\\)")
                     (62 . ".\\(?:\\(?:=>\\|>[=>-]\\)\\|[=>-]\\)")
                     (63 . ".\\(?:\\(\\?\\?\\)\\|[:=?]\\)")
                     (91 . ".\\(?:]\\)")
                     (92 . ".\\(?:\\(?:\\\\\\\\\\)\\|\\\\\\)")
                     (94 . ".\\(?:=\\)")
                     (119 . ".\\(?:ww\\)")
                     (123 . ".\\(?:-\\)")
                     (124 . ".\\(?:\\(?:|[=|]\\)\\|[=>|]\\)")
                     (126 . ".\\(?:~>\\|~~\\|[>=@~-]\\)"))))
        (dolist (char-regexp alist)
          (set-char-table-range composition-function-table (car char-regexp)
                                `([,(cdr char-regexp) 0 font-shape-gstring]))))

      (set-frame-font "Fira Code Retina"))))

(use-package emojify
  :doc "Display Emoji in Emacs."
  :ensure t
  :disabled t
  :init
  (add-hook 'after-init-hook #'global-emojify-mode)
  :delight)


;; ──────────────────────────────────────── *ORG* ───────────────────────────────────────
;; (load-file "~/.emacs.d/org-config.el")

;; Open agenda view when Emacs is started.
;; (jump-to-org-agenda)
;; (delete-other-windows)

(provide 'init)

;;; init.el ends here
