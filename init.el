;;; init.el --- The main entry for emacs -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; Defer GC
(setq gc-cons-threshold most-positive-fixnum)

;; Increase the amount of data from the process
;; `lsp-mode' gains
(setq read-process-output-max (* 1024 1024))

(require 'package)
(setq package-archives
      '(("gnu"   . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
        ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))

(package-initialize)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-and-compile
  (setq use-package-always-ensure nil)
  (setq use-package-always-defer nil)
  (setq use-package-always-demand nil)
  (setq use-package-expand-minimally nil)
  (setq use-package-enable-imenu-support t))
(eval-when-compile
  (require 'use-package))

;; Bootstrap `straight.el'
(defvar bootstrap-version)
(setq straight-vc-git-default-clone-depth 1)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq debug-on-error t)

(add-to-list 'load-path (expand-file-name "plugins" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "plugins/lang" user-emacs-directory))
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'init-base)
(require 'init-startup)
(require 'init-org)
(require 'init-ui)
(require 'init-tools)
(require 'init-evil)
(require 'init-lsp)
(require 'init-git)
(require 'init-dev)
(require 'init-mail)
(require 'init-dired)

;; Facilities for myself
(use-package init-blog
  :ensure nil
  :after markdown-mode
  :bind (:map markdown-mode-map
         ("C-c C-s r" . mblog-insert-ruby-tag)))

(use-package init-mkey
  :ensure nil
  :hook (after-init . mkey-init))

(use-package init-license
  :ensure nil)

(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
