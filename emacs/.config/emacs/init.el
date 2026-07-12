;; GC tuning lives in early-init.el (startup) and the gcmh block (runtime).

(defun start/org-babel-tangle-config ()
  "Automatically tangle our init.org config file when we save it."
  (interactive)
  (when (and (buffer-file-name)  ;; This handles nil buffer-file-name
             ;; Use file-truename to handle simlinks (eg. when using GNU stow)
             ;; Use equal instead of string-equal as file-truename returns list-like structure
             (equal (file-truename (file-name-directory (buffer-file-name)))
                    (file-truename (expand-file-name user-emacs-directory))))
    (let ((org-confirm-babel-evaluate nil)
          (warning-minimum-level :error)      ;; Suppress warnings, they are annoying
          (byte-compile-warnings nil))        ;; Disable byte-compile warnings
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'start/org-babel-tangle-config)))

(defun start/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'start/display-startup-time)

(require 'use-package-ensure) ;; Load use-package-always-ensure
(setq use-package-always-ensure t) ;; Always ensures that a package is installed

(setq package-archives '(("melpa" . "https://melpa.org/packages/") ;; Sets default package repositories
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(setq package-quickstart nil)

(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "etc/" user-emacs-directory)
        no-littering-var-directory "~/.local/share/emacs/")
  :config
  ;; Keep auto-save files (if ever re-enabled) out of the way too.
  (setq auto-save-file-name-transforms
        `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  ;; Don't clutter recentf with our own state files.
  (with-eval-after-load 'recentf
    (add-to-list 'recentf-exclude
                 (recentf-expand-file-name no-littering-var-directory))
    (add-to-list 'recentf-exclude
                 (recentf-expand-file-name no-littering-etc-directory))))

(use-package emacs
  :custom
  ;; Menu/tool/scroll bars are disabled in early-init.el via frame params
  ;; (they're never drawn), so we don't repeat the mode toggles here.
  (inhibit-startup-screen t)  ;; Disable welcome screen

  (delete-selection-mode t)   ;; Select text and delete it by typing.
  (electric-indent-mode nil)  ;; Turn off the weird indenting that Emacs does by default.
  (electric-pair-mode t)      ;; Turns on automatic parens pairing

  (blink-cursor-mode nil)     ;; Don't blink cursor
  (global-auto-revert-mode t) ;; Automatically reload file and show changes if the file has changed

  (recentf-mode t)            ;; Enable recent file mode (needed by consult-recent-file)
  (save-place-mode t)         ;; Reopen files at the cursor position you left them at

  (display-line-numbers-width 4)          ;; Fixed width for line numbers (prevents horizontal shift)
  (global-display-line-numbers-mode t)    ;; Display line numbers (absolute by default)
  (column-number-mode t)                  ;; Display column in mode line

  (mouse-wheel-progressive-speed nil)     ;; Disable progressive speed when scrolling

  (use-short-answers t)       ;; Use short answers (y instead of yes)

  (indent-tabs-mode nil)
  (tab-width 2)

  (make-backup-files nil)     ;; Stop creating ~ backup files
  (auto-save-default nil)     ;; Stop creating # auto save files
  :hook
  (prog-mode . hs-minor-mode) ;; Enable folding hide/show globally
  :config
  ;; Move customization variables to a separate file so init.el stays clean.
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (load custom-file 'noerror 'nomessage)
  :bind (([escape] . keyboard-escape-quit) ;; Escape quits prompts (minibuffer escape)
         ;; C-+ / C-- (or Ctrl + mouse wheel) for zoom in/out.
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("<C-wheel-up>" . text-scale-increase)
         ("<C-wheel-down>" . text-scale-decrease)))

(use-package avy
  :bind ("C-;" . avy-goto-char-timer))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package expand-region
  :bind ("C-=" . er/expand-region))

(use-package vundo
  :bind ("C-c u" . vundo))

(use-package general
  :config
  ;; C-c f prefix: Find operations (files, projects, etc.)
  (general-create-definer start/find-keys
    :prefix "C-c f")

  (start/find-keys
    "" '(:ignore t :wk "Find")
    "f" '(consult-find :wk "Find file (all, includes hidden)")
    "d" '(consult-fd :wk "Find file with fd (respects .gitignore)")
    "p" '(consult-project-extra-find :wk "Find in project (buffers/files/projects)")
    "o" '(consult-project-extra-find-other-window :wk "Find in project other window (buffers/files/projects)")
    "r" '(consult-recent-file :wk "Recent files")
    "l" '(consult-locate :wk "Locate file (system-wide)"))

  ;; C-c s prefix: Search operations (grep, line search, etc.)
  (general-create-definer start/search-keys
    :prefix "C-c s")

  (start/search-keys
    "" '(:ignore t :wk "Search")
    "s" '(consult-line :wk "Search line in buffer")
    "g" '(consult-ripgrep :wk "Ripgrep in project")
    "G" '(consult-git-grep :wk "Git grep in repository")
    "r" '(consult-grep :wk "Grep in directory")
    "i" '(consult-imenu :wk "Search symbols (Imenu)")
    "I" '(consult-imenu-multi :wk "Search symbols across buffers")
    "o" '(consult-outline :wk "Search outline headings")
    "m" '(consult-mark :wk "Jump to mark")
    "M" '(consult-global-mark :wk "Jump to global mark"))

  ;; Extend M-s (built-in search prefix) with consult commands
  ;; M-s is the traditional Emacs search prefix
  (general-define-key
   :keymaps 'search-map  ;; search-map is bound to M-s by default
   "r" '(consult-ripgrep :wk "Ripgrep")
   "l" '(consult-line :wk "Search line")
   "i" '(consult-imenu :wk "Imenu")
   "o" '(consult-outline :wk "Outline"))

  ;; C-c b prefix: Buffer operations
  (general-create-definer start/buffer-keys
    :prefix "C-c b")

  (start/buffer-keys
    "" '(:ignore t :wk "Buffers")
    "b" '(consult-buffer :wk "Switch buffer (all sources)")
    "p" '(consult-project-buffer :wk "Switch project buffer")
    "o" '(consult-buffer-other-window :wk "Switch buffer (other window)")
    "k" '(kill-current-buffer :wk "Kill current buffer")
    "K" '(kill-buffer :wk "Kill buffer (select)")
    "r" '(revert-buffer :wk "Reload buffer")
    "s" '(save-buffer :wk "Save buffer")
    "S" '(save-some-buffers :wk "Save modified buffers"))

  ;; C-c g prefix: Git/Version control operations
  (general-create-definer start/git-keys
    :prefix "C-c g")

  (start/git-keys
    "" '(:ignore t :wk "Git")
    "s" '(magit-status :wk "Magit status")
    "d" '(magit-diff :wk "Magit diff")
    "l" '(magit-log :wk "Magit log")
    "b" '(magit-blame :wk "Magit blame")
    "c" '(magit-commit :wk "Magit commit"))

  ;; C-c e prefix: Language/Eglot operations
  (general-create-definer start/eglot-keys
    :prefix "C-c e")

  (start/eglot-keys
    "" '(:ignore t :wk "Language/Eglot")
    "e" '(eglot-reconnect :wk "Eglot reconnect")
    "f" '(eglot-format :wk "Format buffer")
    "r" '(eglot-rename :wk "Rename symbol")
    "a" '(eglot-code-actions :wk "Code actions")
    "d" '(eldoc-doc-buffer :wk "Show documentation")
    "l" '(consult-flymake :wk "List diagnostics")
    "n" '(flymake-goto-next-error :wk "Next diagnostic")
    "p" '(flymake-goto-prev-error :wk "Previous diagnostic"))

  ;; C-c t prefix: Toggle operations
  (general-create-definer start/toggle-keys
    :prefix "C-c t")

  (start/toggle-keys
    "" '(:ignore t :wk "Toggle")
    "l" '(display-line-numbers-mode :wk "Line numbers")
    "w" '(visual-line-mode :wk "Visual line mode (wrap)")
    "t" '(consult-theme :wk "Switch theme")
    "f" '(toggle-frame-fullscreen :wk "Fullscreen"))

  ;; C-c p prefix: Project operations
  ;; Projectile handles project detection and switching; consult provides the
  ;; preview-rich finders. They're bridged via `consult-project-function' =
  ;; projectile-project-root, so consult commands honor projectile's projects.
  (general-create-definer start/project-keys
    :prefix "C-c p")

  (start/project-keys
    "" '(:ignore t :wk "Project")
    "p" '(projectile-switch-project :wk "Switch project")
    "f" '(consult-project-extra-find :wk "Find file (with preview)")
    "b" '(consult-project-buffer :wk "Switch buffer (with preview)")
    "d" '(projectile-find-dir :wk "Find directory")
    "c" '(projectile-compile-project :wk "Compile")
    "t" '(projectile-test-project :wk "Run tests")
    "r" '(projectile-run-project :wk "Run project")
    "k" '(projectile-kill-buffers :wk "Kill project buffers")
    "i" '(projectile-invalidate-cache :wk "Invalidate cache")
    "D" '(projectile-dired :wk "Dired at root")
    "m" '(ghostel-project :wk "Terminal at root"))

  ;; Additional useful global bindings
  (general-define-key
   "C-x b" '(consult-buffer :wk "Switch buffer")  ;; Replace default switch-to-buffer
   "C-x 4 b" '(consult-buffer-other-window :wk "Switch buffer other window")
   "M-y" '(consult-yank-from-kill-ring :wk "Yank from kill ring")  ;; Better than yank-pop
   "M-g i" '(consult-imenu :wk "Imenu")
   "M-g o" '(consult-outline :wk "Outline")
   "M-g m" '(consult-mark :wk "Jump to mark")
   "M-g M" '(consult-global-mark :wk "Jump to global mark"))
  )

(load-theme 'modus-vivendi-tinted t)

(use-package ultra-scroll
  :init
  (setq scroll-conservatively 101
        scroll-margin 0)        ; important: scroll-margin>0 not yet supported
  :config
  (ultra-scroll-mode 1))

(add-to-list 'default-frame-alist '(alpha-background . 95)) ;; For all new frames henceforth

(set-face-attribute 'default nil
                    :font "JetBrainsMono Nerd Font" ;; Set your favorite type of font or download JetBrains Mono
                    :height 120
                    :weight 'medium)
;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.

(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font")) ;; Set your favorite font
(setq-default line-spacing 0.2)

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom
  (doom-modeline-height 25)     ;; Sets modeline height
  (doom-modeline-bar-width 5))  ;; Sets right bar width

(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook (dired-mode . (lambda () (nerd-icons-dired-mode t))))

(use-package nerd-icons-ibuffer
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(use-package pulsar
  :init (pulsar-global-mode 1)
  :custom
  (pulsar-pulse-on-window-change t))

(use-package spacious-padding
  :init (spacious-padding-mode 1))

(use-package centaur-tabs
  :demand t
  :custom
  (centaur-tabs-set-icons t)
  (centaur-tabs-icon-type 'nerd-icons)
  (centaur-tabs-gray-out-icons 'buffer)
  (centaur-tabs-set-bar 'left)
  (centaur-tabs-set-modified-marker t)
  (centaur-tabs-modified-marker "•")
  (centaur-tabs-close-button "✕")
  (centaur-tabs-cycle-scope 'tabs)
  (centaur-tabs-style "bar")
  (centaur-tabs-height 32)
  :config
  ;; Only show "real" buffers as tabs (skip * and space-prefixed buffers).
  (defun start/tabs-buffer-list ()
    (seq-filter
     (lambda (b)
       (and (buffer-live-p b)
            (let ((name (buffer-name b)))
              (not (or (string-prefix-p " " name)
                       (string-prefix-p "*" name)
                       (string= name ""))))))
     (buffer-list)))
  (setq centaur-tabs-buffer-list-function #'start/tabs-buffer-list)
  ;; Disable the tab bar in transient/popup buffers.
  (dolist (hook '(dashboard-mode-hook calendar-mode-hook
                  helpful-mode-hook help-mode-hook))
    (add-hook hook #'centaur-tabs-local-mode))
  (centaur-tabs-mode 1)
  (centaur-tabs-group-by-projectile-project)
  :bind
  (("C-<tab>"   . centaur-tabs-forward)
   ("C-S-<tab>" . centaur-tabs-backward)
   ("C-c t T"   . centaur-tabs-mode)))  ;; Toggle the tab bar on/off

(use-package exec-path-from-shell
  :init
  (when (or (daemonp) (memq window-system '(mac ns x pgtk)))
    (exec-path-from-shell-initialize)))

(use-package projectile
  :init
  (projectile-mode)
  :config
  (add-hook 'project-find-functions #'project-projectile)
  ;; Auto-populate the known-projects list from the search path on load.
  ;; Negligible cost under emacs --daemon since it only runs at server start.
  (projectile-discover-projects-in-search-path)
  :custom
  (projectile-run-use-comint-mode t) ;; Interactive run dialog when running projects inside emacs (like giving input)
  (projectile-switch-project-action #'projectile-find-file) ;; Drop into find-file on project switch
  (projectile-project-search-path '(("~/dev" . 2)))) ;; Search up to 2 subdirectory levels deep for projects

(use-package eglot
  :ensure nil
  :hook
  ((python-ts-mode
    elixir-ts-mode heex-ts-mode
    typescript-ts-mode tsx-ts-mode js-ts-mode) . eglot-ensure)
  :custom
  (eglot-events-buffer-size 0)
  (eglot-autoshutdown t)
  (eglot-sync-connect 0)
  (eglot-extend-to-xref t)
  :config
  ;; Prefer pyright over pylsp/jedi for Python.
  (add-to-list 'eglot-server-programs
               '((python-ts-mode python-mode) . ("pyright-langserver" "--stdio")))
  ;; Pyright workspace defaults. Django-friendly: basic typing, only diagnose
  ;; open files (faster on big projects). Override per-project via .dir-locals.
  (setq-default eglot-workspace-configuration
                '(:python (:analysis (:typeCheckingMode "basic"
                                      :diagnosticMode "openFilesOnly"
                                      :autoImportCompletions t
                                      :useLibraryCodeForTypes t))))
  ;; Elixir: expert (next-gen) with lexical fallback. Linux-only binary name.
  (when (eq system-type 'gnu/linux)
    (setf (alist-get '(elixir-ts-mode elixir-mode heex-ts-mode)
                     eglot-server-programs nil nil #'equal)
          (eglot-alternatives
           '(("expert_linux_amd64" "--stdio") ("start_lexical.sh"))))))

(defun start/eglot-capf ()
  "Rebuild `completion-at-point-functions' after Eglot takes over."
  (setq-local completion-at-point-functions
              (list (cape-capf-super #'eglot-completion-at-point
                                     #'yasnippet-capf)
                    #'cape-file
                    #'cape-dabbrev)))

(add-hook 'eglot-managed-mode-hook #'start/eglot-capf)

(use-package apheleia
  :diminish apheleia-mode
  :hook (after-init . apheleia-global-mode)
  :config
  ;; Use ruff for Python (fast, modern). Override to 'black if a project prefers.
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff))
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff)))

(use-package sideline-flymake
  :hook (flymake-mode . sideline-mode)
  :custom
  (sideline-flymake-display-mode 'line) ;; Show errors on the current line
  (sideline-backends-right '(sideline-flymake)))

(use-package eldoc-box
  :diminish eldoc-box-hover-at-point-mode
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode)
  :custom
  (eldoc-echo-area-use-multiline-p nil) ;; Keep the echo area quiet; use the box
  (eldoc-box-only-multi-line t)
  (eldoc-box-max-pixel-width 500)
  (eldoc-box-max-pixel-height 300))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

(use-package devdocs
  :bind ("C-h D" . devdocs-lookup))

(use-package aggressive-indent
  :diminish aggressive-indent-mode
  :hook (emacs-lisp-mode . aggressive-indent-mode))

(use-package highlight-defined
  :hook (emacs-lisp-mode . highlight-defined-mode))

(use-package yasnippet
  :diminish yas-minor-mode
  :hook (prog-mode . yas-minor-mode))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package yasnippet-capf
  :after yasnippet
  :custom
  (yasnippet-capf-lookup-by 'key)) ;; Match on snippet key (not name)

(use-package envrc
  :diminish envrc-mode
  :hook (after-init . envrc-global-mode))

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (cmake "https://github.com/uyha/tree-sitter-cmake")
        (c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (elisp "https://github.com/Wilfred/tree-sitter-elisp")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (gomod "https://github.com/camdencheek/tree-sitter-go-mod")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (lua "https://github.com/tjdevries/tree-sitter-lua")
        (make "https://github.com/alemuller/tree-sitter-make")
        (markdown "https://github.com/ikatyang/tree-sitter-markdown")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")
        (heex "https://github.com/phoenixframework/tree-sitter-heex")
        (elixir "https://github.com/elixir-lang/tree-sitter-elixir")))

(defun start/install-treesit-grammars ()
  "Install missing treesitter grammars"
  (interactive)
  (dolist (grammar treesit-language-source-alist)
    (let ((lang (car grammar)))
      (unless (treesit-language-available-p lang)
        (treesit-install-language-grammar lang)))))

;; Call this function to install missing grammars
;; (start/install-treesit-grammars)

;; Additional mode remappings not covered by defaults. Use add-to-list so we
;; don't clobber entries set elsewhere (Emacs or other packages).
(dolist (remap '((yaml-mode . yaml-ts-mode)
                 (sh-mode . bash-ts-mode)
                 (c-mode . c-ts-mode)
                 (c++-mode . c++-ts-mode)
                 (css-mode . css-ts-mode)
                 (python-mode . python-ts-mode)
                 (mhtml-mode . html-ts-mode)
                 (javascript-mode . js-ts-mode)
                 (json-mode . json-ts-mode)
                 (lua-mode . lua-ts-mode)
                 (typescript-mode . typescript-ts-mode)
                 (conf-toml-mode . toml-ts-mode)
                 (elixir-mode . elixir-ts-mode)))
  (add-to-list 'major-mode-remap-alist remap))

;; Or if there is no built in mode
(use-package cmake-ts-mode :ensure nil :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))
(use-package go-ts-mode :ensure nil :mode "\\.go\\'")
(use-package go-mod-ts-mode :ensure nil :mode "\\.mod\\'")
(use-package rust-ts-mode :ensure nil :mode "\\.rs\\'")
(use-package tsx-ts-mode :ensure nil :mode "\\.tsx\\'")

(use-package lua-ts-mode
  :ensure nil
  :mode "\\.lua\\'") ;; Only start in a lua file

(use-package org
  :ensure nil
  :custom
  (org-edit-src-content-indentation 2) ;; Indent src block contents by 2 spaces.
  (org-return-follows-link t)          ;; RET follows links (TOC, URLs, etc.)

  :hook
  (org-mode . org-indent-mode))

(use-package markdown-mode
  :mode (("\\.md\\'"  . gfm-mode)
         ("\\.mdx\\'" . gfm-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t)
  (markdown-header-scaling t)
  (markdown-italic-underscore t))

(use-package elixir-ts-mode
  :hook
  (elixir-ts-mode . (lambda ()
                      (push '(">=" . ?\u2265) prettify-symbols-alist)  ;; ≥
                      (push '("<=" . ?\u2264) prettify-symbols-alist)  ;; ≤
                      (push '("!=" . ?\u2260) prettify-symbols-alist)  ;; ≠
                      (push '("==" . ?\u2A75) prettify-symbols-alist)  ;; ≝
                      (push '("=~" . ?\u2245) prettify-symbols-alist)  ;; ≈
                      (push '("<-" . ?\u2190) prettify-symbols-alist)  ;; ←
                      (push '("->" . ?\u2192) prettify-symbols-alist)  ;; →
                      (push '("|>" . ?\u25B7) prettify-symbols-alist)  ;; ▷
                      (prettify-symbols-mode 1))))

(use-package toc-org
  :commands toc-org-enable
  :hook (org-mode . toc-org-mode))

(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package org-tempo
  :ensure nil
  :after org
  :demand t)

(defun start/get-authinfo-secret (host user)
  "Retrieves and returns the secret from .authinfo given a host and user parameters.
Returns nil if no matching entry is found."
  ;; Store credentials in ~/.authinfo as:
  ;;   machine api.mistral.ai login bearer password api-key-goes-here
  (let* ((auth-data (car (auth-source-search :max 1 :host host :user user)))
         (secret-function (plist-get auth-data :secret)))
    (and secret-function (funcall secret-function))))

(defun start/api-mistral-get-bearer-token ()
  "Retrieves and returns the bearer token for Mistral API."
  (interactive)
  (start/get-authinfo-secret "api.mistral.ai" "bearer"))

(defun start/codestral-mistral-get-bearer-token ()
  "Retrieves and returns the bearer token for Mistral Codestral API."
  (interactive)
  (start/get-authinfo-secret "codestral.mistral.ai" "bearer"))

(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :config
  (let ((api-key (start/api-mistral-get-bearer-token)))
    (when api-key
      (setq gptel-model 'mistral-small
            gptel-backend
            (gptel-make-openai "MistralLeChat"
              :host "api.mistral.ai"
              :endpoint "/v1/chat/completions"
              :protocol "https"
              :key api-key
              :models '("mistral-small"))))))

(use-package minuet
  :bind
  (("M-i" . #'minuet-show-suggestion) ;; use overlay for completion
   ("C-c m i" . #'minuet-complete-with-minibuffer) ;; use minibuffer for completion
   ("C-c m c" . #'minuet-configure-provider)
   :map minuet-active-mode-map
   ;; These keymaps activate only when a minuet suggestion is displayed in the current buffer
   ("M-p" . #'minuet-previous-suggestion) ;; invoke completion or cycle to next completion
   ("M-n" . #'minuet-next-suggestion) ;; invoke completion or cycle to previous completion
   ("M-A" . #'minuet-accept-suggestion) ;; accept whole completion
   ;; Accept the first line of completion, or N lines with a numeric-prefix:
   ;; e.g. C-u 2 M-a will accepts 2 lines of completion.
   ("M-a" . #'minuet-accept-suggestion-line)
   ("M-e" . #'minuet-dismiss-suggestion))

  :init
  ;; if you want to enable auto suggestion.
  ;; Note that you can manually invoke completions without enable minuet-auto-suggestion-mode
  (add-hook 'prog-mode-hook #'minuet-auto-suggestion-mode)

  :config
  ;; Only configure if API key is available
  (let ((api-key (start/codestral-mistral-get-bearer-token)))
    (when api-key
      (setenv "CODESTRAL_API_KEY" api-key)
      ;; You can use M-x minuet-configure-provider to interactively configure provider and model
      (setq minuet-provider 'codestral)
      (minuet-set-optional-options minuet-codestral-options :stop ["\n\n"])
      (minuet-set-optional-options minuet-codestral-options :max_tokens 256)))
  )

(use-package shell-maker
  :defer t)

(use-package acp
  :vc (:url "https://github.com/xenodium/acp.el")
  :defer t)

(use-package agent-shell
  :vc (:url "https://github.com/xenodium/agent-shell")
  :defer t)

(use-package ghostel
  :bind (("C-x m" . ghostel)                 ;; Open a terminal
         :map ghostel-semi-char-mode-map
         ("C-s" . consult-line)              ;; Search the terminal buffer
         ("M-<backspace>" . ghostel-backward-kill-word)
         ("M-p" . (lambda () (interactive) (ghostel-send-key "p" "ctrl")))
         ("M-n" . (lambda () (interactive) (ghostel-send-key "n" "ctrl"))))
  :config
  ;; Offer a terminal when switching projects via project.el's dispatcher.
  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
  ;; Let the terminal call back into Emacs (e.g. open magit from the shell).
  (add-to-list 'ghostel-eval-cmds
               '("magit-status-setup-buffer" magit-status-setup-buffer)))

;; Route eshell visual commands (top, htop, less, ...) through ghostel.
(use-package ghostel-eshell
  :ensure nil
  :after ghostel
  :hook (eshell-load . ghostel-eshell-visual-command-mode))

;; Run `compile'/`recompile' output inside a ghostel terminal.
(use-package ghostel-compile
  :ensure nil
  :after ghostel
  :hook (after-init . ghostel-compile-global-mode))

(defvar start/test-runner-alist
  '((python-ts-mode
     :run            "python %f"
     :test-all       "python -m pytest"
     :test-file      "python -m pytest %f"
     :test-at-point  "python -m pytest %f::%t"
     :test-single    "python -m pytest %f::%t -x")
    (elixir-ts-mode
     :run            "mix run %f"
     :test-all       "mix test"
     :test-file      "mix test %f"
     :test-at-point  "mix test %f:%l"     ;; Elixir selects tests by line
     :test-single    "mix test %f:%l"))
  "Alist of major-mode -> command plist.
Tokens: %f current file, %t test name at point, %l line, %d project root.")

(defvar start/test-name-extractors
  '((python-ts-mode . start/python-test-name-at-point))
  "Alist of major-mode -> function returning the test name at point.")

(defun start/python-test-name-at-point ()
  (save-excursion
    (end-of-line)
    (when (re-search-backward "^\\s-*def \\(test_[A-Za-z0-9_]+\\)" nil t)
      (match-string-no-properties 1))))

(defun start/test--get-config (key)
  (let ((entry (or (alist-get major-mode start/test-runner-alist)
                   (cl-loop for (mode . plist) in start/test-runner-alist
                            when (derived-mode-p mode) return plist))))
    (when entry (plist-get entry key))))

(defun start/test--name-at-point ()
  (let ((fn (alist-get major-mode start/test-name-extractors)))
    (when fn (funcall fn))))

(defun start/test--project-root ()
  (if-let ((proj (project-current))) (project-root proj) default-directory))

(defun start/test--resolve-cmd (cmd)
  (let* ((file  (or (buffer-file-name) ""))
         (root  (start/test--project-root))
         (tname (or (start/test--name-at-point) ""))
         (line  (number-to-string (line-number-at-pos))))
    (thread-last cmd
                 (string-replace "%f" file)
                 (string-replace "%t" tname)
                 (string-replace "%l" line)
                 (string-replace "%d" root))))

(defun start/test--run (key)
  (let ((cmd (start/test--get-config key)))
    (unless cmd
      (user-error "No %s command configured for %s" key major-mode))
    (let* ((resolved (start/test--resolve-cmd cmd))
           ;; With a prefix arg, edit the command before running it.
           (final    (if current-prefix-arg
                         (read-string "Command: " resolved)
                       resolved))
           (default-directory (start/test--project-root)))
      (compile final))))

(defun start/run ()          (interactive) (start/test--run :run))
(defun start/test-all ()     (interactive) (start/test--run :test-all))
(defun start/test-file ()    (interactive) (start/test--run :test-file))
(defun start/test-rerun ()   (interactive) (recompile))
(defun start/test-at-point () (interactive) (start/test--run :test-at-point))
(defun start/test-single ()  (interactive) (start/test--run :test-single))

;; C-c r prefix: Run/test operations
(with-eval-after-load 'general
  (general-create-definer start/run-keys :prefix "C-c r")
  (start/run-keys
    "" '(:ignore t :wk "Run/Test")
    "r" '(start/run :wk "Run file/project")
    "t" '(start/test-at-point :wk "Test at point")
    "s" '(start/test-single :wk "Test at point (stop on first fail)")
    "f" '(start/test-file :wk "Test file")
    "a" '(start/test-all :wk "Test all")
    "l" '(start/test-rerun :wk "Re-run last (recompile)")))

(use-package dired
  :ensure nil
  :custom
  (dired-listing-switches "-lAh --group-directories-first --no-group")
  (dired-dwim-target t)                          ;; Guess target dir from other window
  (dired-kill-when-opening-new-dired-buffer t)   ;; Don't accumulate Dired buffers
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'top)
  (dired-create-destination-dirs 'ask)
  (delete-by-moving-to-trash t))

;; Hide dotfiles by default; toggle with C-x M-o (dired-omit-mode).
(use-package dired-x
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :custom
  (dired-omit-verbose nil)
  (dired-omit-files (concat "\\(?:^\\|/\\)\\.")))

(use-package dirvish
  :init (dirvish-override-dired-mode)
  :custom
  (dirvish-attributes '(nerd-icons subtree-state file-size))
  (dirvish-use-header-line t)
  (dirvish-header-line-format '(:left (path) :right (free-space)))
  (dirvish-subtree-always-show-state t)
  (dirvish-reuse-session 'open)
  (dirvish-preview-dispatchers '(image gif video audio epub archive pdf))
  :bind
  (:map dirvish-mode-map
        ("TAB"   . dirvish-subtree-toggle)
        ("<tab>" . dirvish-subtree-toggle)))

;; Extra font-lock (colored file types/permissions) in Dired buffers.
(use-package diredfl
  :hook (dired-mode . diredfl-mode))

(use-package magit
  :commands magit-status
  :custom
  ;; Open the status buffer full-frame, and restore the previous window
  ;; layout when you bury it (q).
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-bury-buffer-function #'magit-restore-window-configuration))

(use-package diff-hl
  :hook ((dired-mode         . diff-hl-dired-mode-unless-remote)
         (magit-pre-refresh  . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :init (global-diff-hl-mode))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-popupinfo-mode t)
  (corfu-popupinfo-delay 0.5)
  (corfu-separator ?\s)             ;; Orderless field separator, use M-SPC
  (corfu-preview-current nil)       ;; Don't insert completion without confirmation
  (completion-ignore-case t)
  (text-mode-ispell-word-completion nil)  ;; Use cape-dict instead (Emacs 30+)
  (tab-always-indent 'complete)
  :init
  (global-corfu-mode))

(use-package nerd-icons-corfu
  :after corfu
  :init (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :after corfu
  :init
  ;; Functions added later appear earlier in the completion list.
  ;; Order from low to high priority — dabbrev (buffer-local words) is most
  ;; useful for programming, so it goes last.
  (add-to-list 'completion-at-point-functions #'cape-dict)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :init
  (vertico-mode))

(savehist-mode) ;; Enables save history mode

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  :hook
  (marginalia-mode . nerd-icons-completion-marginalia-setup))

(use-package consult-project-extra
  :after (consult project)
  :commands (consult-project-extra-find consult-project-extra-find-other-window))

(use-package consult
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  ;; Include hidden files, exclude .git
  (setq consult-find-args "find . -not ( -path '*/.git/*' -prune )")
  (setq consult-fd-args "fd --hidden --exclude .git --full-path --color=never")
  :config
  ;; Use projectile's project root instead of project.el's
  (autoload 'projectile-project-root "projectile")
  (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;; Enable live preview for the find commands (some default to manual M-.)
  (with-eval-after-load 'consult-project-extra
    (consult-customize
     consult-project-extra-find
     consult-project-extra-find-other-window
     consult-find
     consult-fd
     :preview-key 'any)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-," . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :custom (wgrep-auto-save-buffer t))

(use-package helpful
  ;; `helpful-callable' covers both functions and macros (drop-in for describe-function).
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

(use-package treemacs
  :defer t
  :config
  (treemacs-follow-mode t)
  (treemacs-project-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always)
  (when treemacs-python-executable
    (treemacs-git-commit-diff-mode t))
  (pcase (cons (not (null (executable-find "git")))
               (not (null treemacs-python-executable)))
    (`(t . t) (treemacs-git-mode 'deferred))
    (`(t . _) (treemacs-git-mode 'simple)))
  :bind
  (:map global-map
        ("M-0"       . treemacs-select-window)
        ("C-x t 1"   . treemacs-delete-other-windows)
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag)))

(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once))

(use-package treemacs-magit
  :after (treemacs magit))

(use-package diminish)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init
  (which-key-mode 1)
  :diminish
  :custom
  (which-key-side-window-location 'bottom)
  (which-key-sort-order #'which-key-key-order-alpha) ;; Same as default, except single characters are sorted alphabetically
  (which-key-sort-uppercase-first nil)
  (which-key-add-column-padding 1) ;; Number of spaces to add to the left of each column
  (which-key-min-display-lines 6)  ;; Increase the minimum lines to display, because the default is only 1
  (which-key-idle-delay 0.8)       ;; Set the time delay (in seconds) for the which-key popup to appear
  (which-key-max-description-length 25)
  (which-key-allow-imprecise-window-fit nil)) ;; Fixes which-key window slipping out in Emacs Daemon

(use-package ws-butler
  :diminish ws-butler-mode
  :init (ws-butler-global-mode))

(use-package eldoc
  :ensure nil
  :diminish)

(use-package gcmh
  :diminish gcmh-mode
  :hook (after-init . gcmh-mode)
  :custom
  (gcmh-idle-delay 5)
  (gcmh-high-cons-threshold (* 16 1024 1024)))
