;;; init-dev.el --- Programming development -*- lexical-binding: t -*-

;;; Commentary:
;;

;;; Code:

;; Compilation Mode
(use-package compile
  :ensure nil
  :custom
  (compilation-always-kill t)
  (compilation-scroll-output t)
  (compilation-ask-about-save nil) ;; save all buffers on `compile'
  :hook (compilation-filter . my/colorize-compilation-buffer)
  :config
  (add-to-list 'compilation-finish-functions 'my/notify-compilation-result)
  :preface
  (defun my/colorize-compilation-buffer ()
    "ANSI coloring in compilation buffers."
    (when (eq major-mode 'compilation-mode)
      (ansi-color-apply-on-region compilation-filter-start (point-max))))
  (defun my/notify-compilation-result (_comp-buffer exit-string)
    "Notify after the compilation is done."
    (if (string-match "^finished" exit-string)
        (notifications-notify :title "Compilation"
                              :body "Compilation successful :-)"
                              :timeout 5000
                              :urgency 'normal)
      (notifications-notify :title "Compilation"
                            :body "Compilation failed :-("
                            :timeout 5000
                            :urgency 'critical)))
  )

;; Debugger
(use-package gdb-mi
  :ensure nil
  :hook (gud-mode . gud-tooltip-mode)
  :custom
  (gdb-show-main t)
  (gdb-display-io-nopopup t)
  (gdb-show-changed-values t)
  (gdb-delete-out-of-scope t)
  (gdb-use-colon-colon-notation t)
  (gdb-restore-window-configuration-after-quit t)
  :config
  ;; Add color to the current GUD line
  ;; From https://kousik.blogspot.com/2005/10/highlight-current-line-in-gdbemacs.html
  (defconst gud-highlight-face 'secondary-selection)

  (defvar gud-overlay
    (let ((overlay (make-overlay (point) (point))))
      (overlay-put overlay 'face gud-highlight-face)
      overlay)
    "Overlay variable for GUD highlighting.")

  (define-advice gud-display-line (:after (true-file _line))
    "Highlight gud current line."
    (when-let* ((buffer (gud-find-file true-file)))
      (with-current-buffer buffer
        (move-overlay gud-overlay (line-beginning-position) (line-end-position)
                      (current-buffer)))))

  (define-advice gud-kill-buffer-hook (:after nil)
    "Remove highlight overlay."
    (delete-overlay gud-overlay))

  (define-advice gud-sentinel (:after (_1 _2))
    "Remove highlight overlay when user quit gud."
    (delete-overlay gud-overlay)))

(use-package license
  :ensure t
  :straight (:host github :repo "condy0919/license.el")
  :bind (:map prog-mode-map
         ("C-c i l" . license-insert))
  :custom
  (license-copyright-holder 'auto)
  (license-project-detection 'projectile))

;; Highlight TODO
(use-package hl-todo
  :ensure t
  :bind (:map hl-todo-mode-map
         ("C-c t p" . hl-todo-previous)
         ("C-c t n" . hl-todo-next)
         ("C-c t o" . hl-todo-occur))
  :hook (after-init . global-hl-todo-mode)
  :config
  (dolist (keyword '("BUG" "ISSUE" "NB"))
    (cl-pushnew `(,keyword . ,(face-foreground 'error)) hl-todo-keyword-faces)))

;; Show trailing whitespaces
(use-package whitespace
  :ensure nil
  :hook ((prog-mode markdown-mode conf-mode) . whitespace-mode)
  :custom
  (whitespace-style '(face trailing)))

;; Visual diff interface
(use-package ediff
  :ensure nil
  :hook (ediff-quit . winner-undo) ;; restore windows layout
  :custom
  (ediff-diff-options "-w") ;; turn off whitespace checking
  (ediff-highlight-all-diffs t)
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-merge-split-window-function 'split-window-horizontally))

;; Quickrun codes, including cpp. awesome!
(use-package quickrun
  :ensure t
  :custom
  (quickrun-focus-p nil)
  (quickrun-input-file-extension ".qr")
  :bind (("C-c x" . quickrun)))

;; Superb compiler explorer implementation
(use-package rmsbolt
  :ensure t
  :defer 1
  :custom
  (rmsbolt-asm-format nil)
  (rmsbolt-default-directory "/tmp"))

;; Project management
(use-package projectile
  :ensure t
  :bind (:map projectile-mode-map
         ("C-c p" . projectile-command-map))
  :hook (prog-mode . projectile-mode)
  :custom
  (projectile-completion-system 'ivy)
  (projectile-indexing-method 'hybrid)
  (projectile-globally-ignored-file-suffixes '(".elc" ".pyc" ".o" ".swp" ".so"))
  (projectile-ignored-project-function 'projectile-project-ignore-p)
  :config
  (defconst projectile-ignored-project-directories `("/tmp/"
                                                     ,(file-truename (expand-file-name "straight/" user-emacs-directory))))
  (defun projectile-project-ignore-p (file)
    (cl-loop for ig-dir in projectile-ignored-project-directories
             when (string-prefix-p ig-dir file)
             return t)
    )

  (dolist (dir '(".ccls-cache"
                 ".clangd"
                 ".vscode"
                 "bazel-bin"
                 "bazel-out"
                 "bazel-testlogs"))
    (add-to-list 'projectile-globally-ignored-directories dir))
  (dolist (file '(".DS_Store"))
    (add-to-list 'projectile-globally-ignored-files file))
  )

;; Comprehensive ivy integration for projectile
(use-package counsel-projectile
  :ensure t
  :after counsel projectile
  :hook (prog-mode . counsel-projectile-mode))

;; Lint tool
(use-package flycheck
  :ensure t
  :hook (prog-mode . flycheck-mode)
  :custom
  (flycheck-temp-prefix ".flycheck")
  (flycheck-check-syntax-automatically '(save mode-enabled))
  (flycheck-emacs-lisp-load-path 'inherit)
  (flycheck-indication-mode 'right-fringe)
  ;; clang/gcc/cppcheck flycheckers never know the include path
  (flycheck-disabled-checkers '(c/c++-clang c/c++-cppcheck c/c++-gcc))
  :config
  (define-advice flycheck-global-teardown (:around (func &rest args))
    "Ignore errors.
Such as \"Selete deleted buffer\"
"
    (ignore-errors (apply func args)))
  )

(use-package flymake
  :ensure nil
  :disabled
  :custom
  (flymake-fringe-indicator-position 'right-fringe))

;; Interactive spell checker
(use-package ispell
  :ensure nil
  :when (executable-find "hunspell")
  :bind (("C-c i c" . ispell-comments-and-strings)
         ("C-c i k" . ispell-kill-ispell)
         ("C-c i m" . ispell-message)
         ("C-c i r" . ispell-region))
  :custom
  (ispell-dictionary "en_US")
  (ispell-program-name "hunspell")
  (ispell-following-word t)
  (ispell-personal-dictionary (expand-file-name "hunspell_dict.txt" user-emacs-directory)))

;; Spell check on-the-fly
(use-package flyspell
  :ensure nil
  :hook (git-commit-mode . flyspell-mode)
  :custom
  (flyspell-use-meta-tab nil)
  (flyspell-issue-welcome-flag nil)
  (flyspell-issue-message-flag nil)
  ;; "C-;" is captured by fcitx
  (flyspell-auto-correct-binding (kbd "C-M-;")))

;; xref
(use-package ivy-xref
  :ensure t
  :init
  ;; xref initialization is different in Emacs 27 - there are two different
  ;; variables which can be set rather than just one
  (when (>= emacs-major-version 27)
    (setq xref-show-definitions-function #'ivy-xref-show-defs))
  ;; Necessary in Emacs <27. In Emacs 27 it will affect all xref-based
  ;; commands other than xref-find-definitions (e.g. project-find-regexp)
  ;; as well
  (setq xref-show-xrefs-function #'ivy-xref-show-xrefs))

;; Jump to definition, used as a fallback of lsp-find-definition
(use-package dumb-jump
  :ensure t
  :bind (("M-g o" . dumb-jump-go-other-window)
         ("M-g j" . dumb-jump-go)
         ("M-g q" . dumb-jump-quick-look)
         ("M-g b" . dumb-jump-back)
         ("M-g i" . dumb-jump-go-prompt)
         ("M-g x" . dumb-jump-go-prefer-external)
         ("M-g z" . dumb-jump-go-prefer-external-other-window))
  :custom
  (dumb-jump-quiet t)
  (dumb-jump-aggressive t)
  (dumb-jump-selector 'ivy)
  (dump-jump-prefer-searcher 'rg))

;; pulse current line
(use-package pulse
  :ensure nil
  :custom-face
  (pulse-highlight-start-face ((t (:inherit highlight))))
  (pulse-highlight-face ((t (:inherit highlight))))
  :preface
  (defun my/pulse-line (&rest _)
    "Pulse the current line."
    (pulse-momentary-highlight-one-line (point)))
  (defun my/recenter-and-pulse (&rest _)
    "Recenter and pulse the current line."
    (recenter)
    (my/pulse-line))
  :hook ((counsel-grep-post-action
          dumb-jump-after-jump
          bookmark-after-jump
          imenu-after-jump) . my/recenter-and-pulse)
  :init
  ;; better evil notification
  (advice-add #'evil-goto-line       :after #'my/recenter-and-pulse)
  (advice-add #'evil-goto-mark-line  :after #'my/recenter-and-pulse)
  (advice-add #'what-cursor-position :after #'my/pulse-line)
  (advice-add #'evil-window-top      :after #'my/pulse-line)
  (advice-add #'evil-window-middle   :after #'my/pulse-line)
  (advice-add #'evil-window-bottom   :after #'my/pulse-line))

;; Hiding structured data
;;
;; zm hide-all
;; zr show-all
;; za toggle-fold
;; zo show-block
;; zc hide-block
(use-package hideshow
  :ensure nil
  :hook (prog-mode . hs-minor-mode)
  :config
  (defconst hideshow-folded-face '((t (:inherit 'font-lock-comment-face :box t))))

  (defun hideshow-folded-overlay-fn (ov)
    (when (eq 'code (overlay-get ov 'hs))
      (let* ((nlines (count-lines (overlay-start ov) (overlay-end ov)))
             (info (format " ... #%d " nlines)))
        (overlay-put ov 'display (propertize info 'face hideshow-folded-face)))))

  (setq hs-set-up-overlay 'hideshow-folded-overlay-fn))

;; Antlr mode
(use-package antlr-mode
  :ensure nil
  :mode ("\\.g4\\'" . antlr-mode))

;; Shell mode
(use-package sh-script
  :ensure nil
  :mode ("\\.sh\\'" . sh-mode)
  :bind (:map sh-mode-map
         ("C-c C-e" . sh-execute-region))
  :custom
  (sh-basic-offset 2)
  (sh-indentation 2))

;; CSS
(use-package css-mode
  :ensure nil
  :mode ("\\.scss\\'" . scss-mode)
  :custom
  (css-indent-offset 2))

;; XML
(use-package nxml-mode
  :ensure nil
  :mode (("\\.xml\\'" . nxml-mode)
         ("\\.rss\\'" . nxml-mode))
  :magic "<\\?xml"
  :custom
  (nxml-slash-auto-complete-flag t)
  (nxml-auto-insert-xml-declaration-flag t))

;; Config files mode
(use-package yaml-mode
  :ensure t
  :mode (("\\.yaml\\'" . yaml-mode)
         ("\\.yml\\'"  . yaml-mode)))

;; Syntax highlighting for systemd files
(use-package conf-mode
  :ensure nil
  :mode ((rx "."
             (or "automount" "busname" "link" "mount" "netdev" "network"
                 "path" "service" "slice" "socket" "swap" "target" "timer")
             string-end) . conf-toml-mode))

(require 'init-cpp)
(require 'init-rust)
(require 'init-ocaml)
(require 'init-bazel)
(require 'init-haskell)
(require 'init-python)
(require 'init-elisp)
(require 'init-sql)

(provide 'init-dev)

;;; init-dev.el ends here
