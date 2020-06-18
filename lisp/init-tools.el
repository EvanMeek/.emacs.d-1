;;; init-tools.el --- We all like productive tools -*- lexical-binding: t -*-

;;; Commentary:
;;

;;; Code:

;; Tips for next keystroke
(use-package which-key
  :ensure t
  :hook (after-init . which-key-mode)
  :custom
  (which-key-idle-delay 0.5)
  (which-key-add-column-padding 1)
  :config
  (dolist (k '(("C-c !" "flycheck")
               ("C-c @" "hideshow")
               ("C-c i" "ispell")
               ("C-c n" "org-roam")
               ("C-c t" "hl-todo")
               ("C-x a" "abbrev")
               ("C-x n" "narrow")))
    (cl-destructuring-bind (key name) k
      (which-key-add-key-based-replacements key name)))
  )

;; The blazing grep tool
;; Press C-c s to search
(use-package rg
  :ensure t
  :when (executable-find "rg")
  :hook (after-init . rg-enable-default-bindings))

;; Jump to arbitrary positions
(use-package avy
  :ensure t
  ;; integrate with isearch and others
  ;; C-' to select isearch-candidate with avy
  :hook (after-init . avy-setup-default)
  :custom
  (avy-timeout-seconds 0.2)
  (avy-all-windows nil)
  (avy-background t)
  (avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l ?q ?w ?e ?r ?u ?i ?o ?p))
  :config
  ;; Force to use pre `avy-style'
  (define-advice avy-isearch (:around (func &rest args))
    (let ((avy-style 'pre))
      (apply func args)))
  )

;; ivy core
(use-package ivy
  :ensure t
  :hook (after-init . ivy-mode)
  :bind (("C-c C-r" . ivy-resume)
         :map ivy-minibuffer-map
         ("C-c C-e" . my/ivy-woccur)
         :map ivy-occur-mode-map
         ("C-c C-e" . ivy-wgrep-change-to-wgrep-mode)
         :map ivy-occur-grep-mode-map
         ("C-c C-e" . ivy-wgrep-change-to-wgrep-mode))
  :custom
  (ivy-display-style 'fancy)          ;; fancy style
  (ivy-count-format "%d/%d ")         ;; better counts
  (ivy-use-virtual-buffers t)         ;; show recent files
  (ivy-extra-directories '("./"))     ;; no ".." directories
  (ivy-height 10)
  (ivy-fixed-height-minibuffer t)     ;; fixed height
  (ivy-on-del-error-function 'ignore) ;; dont quit minibuffer when del-error
  :config
  ;; Bring C-' back
  (use-package ivy-avy
    :ensure t)

  ;; Copy from
  ;; https://github.com/honmaple/maple-emacs/blob/master/lisp/init-ivy.el
  (defun my/ivy-woccur ()
    "ivy-occur with wgrep-mode enabled."
    (interactive)
    (run-with-idle-timer 0 nil 'ivy-wgrep-change-to-wgrep-mode)
    (ivy-occur))
  )

;; Fuzzy matcher
(use-package counsel
  :ensure t
  :hook (ivy-mode . counsel-mode)
  :bind (([remap evil-ex-registers]  . counsel-evil-registers)
         ([remap evil-show-marks]    . counsel-mark-ring)
         ([remap evil-show-jumps]    . my/evil-jump-list)
         ([remap recentf-open-files] . counsel-recentf)
         ([remap swiper]             . counsel-grep-or-swiper)
         ("M-y"                      . counsel-yank-pop))
  :config
  (ivy-set-actions
   'counsel-find-file
   '(("d" my/delete-file "delete")
     ("r" my/rename-file "rename")
     ("l" vlf            "view large file")
     ("b" hexl-find-file "open file in binary mode")
     ("x" counsel-find-file-as-root "open as root")))

  ;; Modified from doom
  (defun my/evil-jump-list ()
    "evil jump list with ivy enhancement."
    (interactive)
    (ivy-read "evil jumplist: "
              (nreverse
               (delete-dups
                (mapcar (lambda (mark)
                          (cl-destructuring-bind (pt path) mark
                            (let ((buf (get-file-buffer path)))
                              (unless buf
                                (setq buf (find-file-noselect path t)))
                              (with-current-buffer buf
                                (goto-char pt)
                                (font-lock-fontify-region (line-beginning-position) (line-end-position))
                                (cons (format "%s:%d %s"
                                              (buffer-name)
                                              (line-number-at-pos)
                                              (string-trim-right (or (thing-at-point 'line) "")))
                                      (point-marker))))))
                        (evil--jumps-savehist-sync))))
              :sort nil
              :require-match t
              :action (lambda (cand)
                        (let ((mark (cdr cand)))
                          (with-current-buffer (switch-to-buffer (marker-buffer mark))
                            (goto-char (marker-position mark)))))))
  :custom
  (counsel-preselect-current-file t)
  (counsel-yank-pop-preselect-last t)
  (counsel-yank-pop-separator "\n-----------\n")
  (counsel-find-file-at-point t)
  (counsel-find-file-ignore-regexp "\\(?:\\`\\(?:\\.\\|__\\)\\|elc\\|pyc$\\)"))

;; Use swiper less, it takes up `ivy-height' lines.
(use-package isearch
  :ensure nil
  :bind (:map isearch-mode-map
         ;; consistent with ivy-occur
         ("C-c C-o" . isearch-occur)
         ;; Edit the search string instead of jumping back
         ([remap isearch-delete-char] . isearch-del-char))
  :custom
  ;; One space can represent a sequence of whitespaces
  (isearch-lax-whitespace t)
  (isearch-regexp-lax-whitespace t)
  (search-whitespace-regexp "[ \t\r\n]+")
  (isearch-lazy-count t)
  (isearch-yank-on-move t)
  (lazy-count-prefix-format nil)
  (lazy-count-suffix-format " [%s/%s]")
  (lazy-highlight-cleanup nil)
  :config
  (define-advice isearch-occur (:after (_regexp &optional _nlines))
    (isearch-exit))
  )

;; isearch alternative
(use-package swiper
  :ensure t
  :defer t
  :custom
  (swiper-action-recenter t))

;; Writable grep buffer. company well with ivy-occur
(use-package wgrep
  :ensure t
  :defer 1
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file t))

;; View/Edit reStructuredText file
(use-package rst
  :ensure nil
  :mode (("\\.rst\\'"  . rst-mode)
         ("\\.rest\\'" . rst-mode)))

;; Pixel alignment for org/markdown tables
(use-package valign
  :ensure t
  :straight (:host github :repo "casouri/valign")
  :hook ((markdown-mode org-mode) . valign-mode)
  :config
  ;; compatible with outline mode
  (define-advice outline-show-entry (:override nil)
    "Show the body directly following this heading.
Show the heading too, if it is currently invisible."
    (interactive)
    (save-excursion
      (outline-back-to-heading t)
      (outline-flag-region (max (point-min) (1- (point)))
                           (progn
                             (outline-next-preface)
                             (if (= 1 (- (point-max) (point)))
                                 (point-max)
                               (point)))
                           nil)))
  )

;; The markdown mode is awesome! unbeatable
(use-package markdown-mode
  :ensure t
  :mode ("README\\(?:\\.md\\)?\\'" . gfm-mode)
  :hook (markdown-mode . auto-fill-mode)
  :init
  (advice-add #'markdown--command-map-prompt :override #'ignore)
  (advice-add #'markdown--style-map-prompt   :override #'ignore)
  :custom
  (markdown-header-scaling t)
  (markdown-enable-wiki-links t)
  (markdown-italic-underscore t)
  (markdown-asymmetric-header t)
  (markdown-gfm-uppercase-checkbox t)
  (markdown-fontify-code-blocks-natively t))

;; Generate table of contents for markdown-mode
(use-package markdown-toc
  :ensure t
  :after markdown-mode
  :bind (:map markdown-mode-command-map
         ("r" . markdown-toc-generate-or-refresh-toc)))

;; Free hands
(use-package auto-package-update
  :ensure t
  :defer t
  :custom
  (auto-package-update-delete-old-versions t))

;; GC optimization
(use-package gcmh
  :ensure t
  :custom
  (gcmh-idle-delay 10)
  (gcmh-high-cons-threshold #x6400000) ;; 100 MB
  :hook (after-init . gcmh-mode))

;; Write documentation comment in an easy way
(use-package separedit
  :ensure t
  :custom
  (separedit-default-mode 'markdown-mode)
  (separedit-remove-trailing-spaces-in-comment t)
  (separedit-continue-fill-column t)
  (separedit-buffer-creation-hook #'auto-fill-mode)
  :bind (:map prog-mode-map
         ("C-c '" . separedit)))

;; Pastebin service
(use-package webpaste
  :ensure t
  :defer 1
  :custom
  (webpaste-open-in-browser t)
  (webpaste-paste-confirmation t)
  (webpaste-add-to-killring nil)
  (webpaste-provider-priority '("paste.mozilla.org" "dpaste.org" "ix.io")))

;; Edit text for browser with GhostText or AtomicChrome extension
(use-package atomic-chrome
  :ensure t
  :commands (evil-set-initial-state)
  :hook ((emacs-startup . atomic-chrome-start-server)
         (atomic-chrome-edit-mode . delete-other-windows))
  :custom
  (atomic-chrome-buffer-open-style 'frame)
  (atomic-chrome-default-major-mode 'markdown-mode)
  (atomic-chrome-url-major-mode-alist '(("github\\.com" . gfm-mode)))
  :config
  ;; The browser is in "insert" state, makes it consistent
  (evil-set-initial-state 'atomic-chrome-edit-mode 'insert))

;; Open very large files
(use-package vlf-setup
  :ensure vlf)

;; Notes manager
(use-package deft
  :ensure t
  :defines (org-directory)
  :bind ("C-c n d" . deft)
  :custom
  (deft-recursive t)
  ;; Disable auto save
  (deft-auto-save-interval 0)
  (deft-extensions '("org" "md"))
  (deft-directory org-directory)
  (deft-use-filename-as-title t)
  (deft-use-filter-string-for-filename t)
  (deft-file-naming-rules '((noslash . "-")
                            (nospace . "-")
                            (case-fn . downcase))))

;; Visual bookmarks
(use-package bm
  :ensure t
  :hook ((after-init   . bm-repository-load)
         (find-file    . bm-buffer-restore)
         (after-revert . bm-buffer-restore)
         (kill-buffer  . bm-buffer-save)
         (kill-emacs   . (lambda ()
                           (bm-buffer-save-all)
                           (bm-repository-save))))
  :custom
  (bm-annotate-on-create t)
  (bm-buffer-persistence t)
  (bm-cycle-all-buffers t)
  (bm-goto-position nil)
  (bm-in-lifo-order t)
  (bm-recenter t))

;; Grammar & Style checker
(use-package langtool
  :ensure t
  :bind (("C-x 4 w" . langtool-check)
         ("C-x 4 W" . langtool-check-done)
         ("C-x 4 l" . langtool-switch-default-language)
         ("C-x 4 4" . langtool-show-message-at-point)
         ("C-x 4 c" . langtool-correct-buffer))
  :custom
  (langtool-http-server-host "localhost")
  (langtool-http-server-port 8081))

;; RSS reader
;; The builtin newsticker is buggy
(use-package elfeed
  :ensure t
  :bind ("C-x 4 n" . elfeed)
  :custom
  (elfeed-feeds '(("https://planet.emacslife.com/atom.xml" Planet-Emacslife)
                  ("https://lwn.net/headlines/rss" LWN)))
  (elfeed-search-title-max-width 100))

(provide 'init-tools)

;;; init-tools.el ends here
