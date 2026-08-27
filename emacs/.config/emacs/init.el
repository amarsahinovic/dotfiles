;;; init.el --- Tangled from init.org -*- lexical-binding: t; -*-

(defun start/org-babel-tangle-config ()
  "Automatically tangle our init.org config file when we save it."
  (interactive)
  (when (and (buffer-file-name)  ;; This handles nil buffer-file-name
             (derived-mode-p 'org-mode) ;; Only tangle org buffers
             ;; Use file-truename to handle simlinks (eg. when using GNU stow)
             ;; Use equal instead of string-equal as file-truename returns list-like structure
             (equal (file-truename (file-name-directory (buffer-file-name)))
                    (file-truename (expand-file-name user-emacs-directory))))
    (let ((org-confirm-babel-evaluate nil)
          (warning-minimum-level :error)      ;; Suppress warnings, they are annoying
          (byte-compile-warnings nil))        ;; Disable byte-compile warnings
      (org-babel-tangle))))

;; :local is important -- without it the save hook becomes global and fires
;; on every save of every buffer once any org file has been opened.
(add-hook 'org-mode-hook
          (lambda () (add-hook 'after-save-hook #'start/org-babel-tangle-config nil :local)))

(defun start/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'start/display-startup-time)

(require 'use-package-ensure) ;; Load use-package-always-ensure
(setq use-package-always-ensure t) ;; Always ensures that a package is installed

;; Note: Org ELPA (orgmode.org/elpa) was retired in 2022 -- org ships from GNU ELPA.
(setq package-archives '(("melpa" . "https://melpa.org/packages/") ;; Sets default package repositories
                         ("elpa" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
;; Prefer stable GNU/nonGNU releases over MELPA snapshots when a package is
;; on both; MELPA remains the fallback for everything else.
(setq package-archive-priorities '(("elpa" . 3) ("nongnu" . 2) ("melpa" . 1)))

(use-package no-littering
  :demand t
  :init
  (setq no-littering-etc-directory (expand-file-name "etc/" user-emacs-directory)
        no-littering-var-directory "~/.local/share/emacs/")
  :config
  ;; Route backups and auto-save files into var/backup/ and var/auto-save/
  ;; (and skip them for /tmp and TRAMP files, which could leak secrets).
  ;; Backups themselves are enabled in Good Defaults.
  (no-littering-theme-backups)
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
  (auto-revert-avoid-polling t)  ;; Use inotify file notifications instead of polling every 5s
  (auto-revert-check-vc-info t)  ;; Keep the modeline branch name honest after external git ops
  (context-menu-mode t)          ;; Right-click opens a proper context menu

  (recentf-mode t)            ;; Enable recent file mode (needed by consult-recent-file)
  (save-place-mode t)         ;; Reopen files at the cursor position you left them at
  (savehist-mode t)           ;; Persist minibuffer history (vertico ordering) across sessions

  (winner-mode t)             ;; Undo/redo window layouts with C-c left / C-c right
  (repeat-mode t)             ;; Repeat command chords by the last key (e.g. C-x o o o)
  (global-so-long-mode t)     ;; Stay responsive in files with very long lines (minified, etc.)

  (display-line-numbers-width 4)          ;; Fixed width for line numbers (prevents horizontal shift)
  ;; Line numbers via prog/conf hooks below (not globally) so terminals,
  ;; org, dired, help buffers etc. stay clean.
  (column-number-mode t)                  ;; Display column in mode line

  (mouse-wheel-progressive-speed nil)     ;; Disable progressive speed when scrolling
  (mouse-drag-copy-region t)              ;; Mouse selection goes straight to the kill ring

  (ring-bell-function 'ignore)            ;; No beeping or flashing, ever (C-g etc.)

  (use-short-answers t)       ;; Use short answers (y instead of yes)

  ;; Minibuffer behavior
  (enable-recursive-minibuffers t)          ;; Allow M-x etc. while a minibuffer prompt is open
  (minibuffer-depth-indicate-mode t)        ;; ...and show [2] so nesting is visible
  (read-file-name-completion-ignore-case t) ;; Case-insensitive file prompts
  (read-buffer-completion-ignore-case t)    ;; Case-insensitive buffer prompts

  (isearch-lazy-count t)             ;; Show (3/17) match counter in plain C-s
  (kill-do-not-save-duplicates t)    ;; Don't clutter the kill ring with repeats
  (help-window-select t)             ;; Focus help windows so q dismisses them immediately
  (sentence-end-double-space nil)    ;; Single space ends a sentence (fixes M-a/M-e, filling)

  ;; This config is GNU-stowed symlinks into a git repo -- without this Emacs
  ;; asks "Symbolic link to Git-controlled source file; follow link?" constantly.
  (vc-follow-symlinks t)

  ;; Emacs 31 quality-of-life
  (kill-region-dwim 'emacs-word)   ;; C-w with no region kills the word before point
  (delete-pair-push-mark t)        ;; delete-pair marks what was inside, so C-x C-x selects it
  (ibuffer-human-readable-size t)  ;; KB/MB in ibuffer instead of raw byte counts

  (indent-tabs-mode nil)
  (tab-width 2)

  ;; Backups and auto-save as cheap data-loss insurance. no-littering routes
  ;; both into ~/.local/share/emacs/ (backup/ and auto-save/), so nothing
  ;; lands next to the real files.
  (make-backup-files t)
  (backup-by-copying t)       ;; Don't break symlinks/hardlinks (stowed files!)
  (version-control t)         ;; Numbered backups...
  (delete-old-versions t)     ;; ...pruned automatically
  (kept-new-versions 6)
  (kept-old-versions 2)
  (auto-save-default t)       ;; Periodic #file# snapshots between saves
  (create-lockfiles nil)      ;; No .#file symlinks -- they churn Vite/Phoenix watchers,
                              ;; and protect nothing on a single-user machine
  :hook
  (prog-mode . hs-minor-mode) ;; Enable folding hide/show globally
  (prog-mode . display-line-numbers-mode) ;; Line numbers where they matter...
  (conf-mode . display-line-numbers-mode) ;; ...including config-file modes
  :init
  ;; `keyboard-escape-quit' also runs `delete-other-windows' when there are
  ;; multiple windows -- a stray ESC nukes the window layout. This is the
  ;; same command minus that branch (and the buried-buffer one).
  (defun start/escape-quit ()
    "Quit the minibuffer, a prefix arg, or an active region -- nothing else."
    (interactive)
    (cond ((region-active-p) (deactivate-mark))
          ((> (minibuffer-depth) 0) (abort-recursive-edit))
          (current-prefix-arg nil)
          ((> (recursion-depth) 0) (exit-recursive-edit))
          (buffer-quit-function (funcall buffer-quit-function))))
  :config
  ;; Move customization variables to a separate file so init.el stays clean.
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (load custom-file 'noerror 'nomessage)
  :bind (([escape] . start/escape-quit) ;; Escape quits prompts without touching windows
         ;; C-+ / C-- (or Ctrl + mouse wheel) for zoom in/out.
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("<C-wheel-up>" . text-scale-increase)
         ("<C-wheel-down>" . text-scale-decrease)))

(use-package window
  :ensure nil
  :custom
  (display-buffer-alist
   '(;; Ephemeral noise -> shallow bottom side window
     ("\\*\\(Messages\\|Warnings\\|Backtrace\\|Compile-Log\\|Occur\\)\\*"
      (display-buffer-in-side-window)
      (window-height . 0.25) (side . bottom) (slot . 0))
     ;; Compilation / test-runner output -> taller bottom window
     ("\\*compilation\\*"
      (display-buffer-in-side-window)
      (window-height . 0.30) (side . bottom) (slot . 1))
     ;; Flymake diagnostics list (C-c e l uses consult, but the buffer too)
     ("\\*Flymake diagnostics"
      (display-buffer-in-side-window)
      (window-height . 0.25) (side . bottom) (slot . 2))
     ;; Documentation -> right side window ([Hh]elp also catches *helpful ...*)
     ("\\*\\([Hh]elp\\|eldoc\\|devdocs\\)"
      (display-buffer-in-side-window)
      (window-width . 0.35) (side . right) (slot . 0)))))

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

(load-theme 'doom-vibrant t)

(use-package ultra-scroll
  :init
  (setq scroll-conservatively 101
        scroll-margin 0)        ; important: scroll-margin>0 not yet supported
  :config
  (ultra-scroll-mode 1))

(add-to-list 'default-frame-alist '(alpha-background . 98)) ;; For all new frames henceforth

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

;; nerd-icons in Dired come from dirvish's `nerd-icons' attribute, so no
;; separate nerd-icons-dired is needed.

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
  ;; For some reason enabling this below breaks tabs in emacsclient
  ;; https://github.com/ema2159/centaur-tabs/issues/127#issuecomment-3865209191
  ;; (centaur-tabs-set-bar 'left)
  (centaur-tabs-set-modified-marker t)
  (centaur-tabs-modified-marker "•")
  (centaur-tabs-close-button "✕")
  (centaur-tabs-cycle-scope 'tabs)
  (centaur-tabs-style "bar")
  (centaur-tabs-height 32)
  :config
  ;; Only show "real" buffers as tabs (skip * and space-prefixed buffers),
  ;; but keep ghostel terminals (*ghostel...*) -- they're working buffers.
  (defun start/tabs-buffer-list ()
    (seq-filter
     (lambda (b)
       (and (buffer-live-p b)
            (let ((name (buffer-name b)))
              (not (or (string-prefix-p " " name)
                       (and (string-prefix-p "*" name)
                            (not (string-prefix-p "*ghostel" name)))
                       (string-prefix-p "PREVIEW ::" name)
                       (string= name ""))))))
     (buffer-list)))
  (setq centaur-tabs-buffer-list-function #'start/tabs-buffer-list)
  ;; Disable the tab bar in transient/popup buffers.
  (dolist (hook '(calendar-mode-hook helpful-mode-hook help-mode-hook))
    (add-hook hook #'centaur-tabs-local-mode))
  (centaur-tabs-mode 1)
  ;; Group tabs by project name; the default `centaur-tabs-buffer-groups'
  ;; derives the name from project.el's `project-current'.
  (centaur-tabs-group-buffer-groups)
  :bind
  (("C-<tab>"   . centaur-tabs-forward)
   ("C-S-<tab>" . centaur-tabs-backward)
   ("C-c t T"   . centaur-tabs-mode)))  ;; Toggle the tab bar on/off

(use-package exec-path-from-shell
  :init
  (when (or (daemonp) (memq window-system '(mac ns x pgtk)))
    (exec-path-from-shell-initialize)))

(use-package project
  :demand t   ;; Load at startup so the keymap below is bound.
  :custom
  ;; On selecting a project, drop straight into the consult file finder
  ;; (mirrors the old projectile-find-file switch action, but with preview).
  (project-switch-commands #'consult-project-extra-find)
  ;; Monorepo support: treat subdirectories with these markers as project
  ;; roots of their own, so Eglot and project commands scope correctly.
  (project-vc-extra-root-markers '("mix.exs" "package.json" "pyproject.toml"
                                   "go.mod" "Cargo.toml"))
  :config
  ;; Reuse project.el's own `project-prefix-map' (the full native C-x p menu:
  ;; find-regexp, query-replace, shell, eshell, vc-dir, ...) rather than
  ;; hand-maintaining a parallel list. Just swap in the consult finders for
  ;; f/b and add a terminal on m; everything else stays on the native C-x p.
  (keymap-set project-prefix-map "f" #'consult-project-extra-find)
  (keymap-set project-prefix-map "b" #'consult-project-buffer)
  (keymap-set project-prefix-map "m" #'ghostel-project)
  ;; Auto-populate project.el's known-projects list from ~/dev, up to two
  ;; directory levels deep -- the replacement for
  ;; projectile-discover-projects-in-search-path. Remembering a directory
  ;; scans its immediate children for projects, so we call it on ~/dev (depth
  ;; 1) and on each of its subdirectories (depth 2). Runs once at startup;
  ;; negligible cost under emacs --daemon since it only runs at server start.
  (defun start/remember-projects ()
    "Discover git projects under ~/dev (one and two levels deep)."
    (let ((root (expand-file-name "~/dev")))
      (when (file-directory-p root)
        (project-remember-projects-under root)
        (dolist (dir (directory-files root t "\\`[^.]"))
          (when (file-directory-p dir)
            (project-remember-projects-under dir))))))
  (start/remember-projects))

(use-package eglot
  :ensure nil
  :hook
  ((python-ts-mode
    elixir-ts-mode heex-ts-mode
    typescript-ts-mode tsx-ts-mode js-ts-mode) . eglot-ensure)
  :custom
  (eglot-events-buffer-config '(:size 0)) ;; Replaces obsolete eglot-events-buffer-size
  (eglot-send-changes-idle-time 0.1)      ;; Snappier diagnostics (default 0.5s)
  (eglot-autoshutdown t)
  (eglot-sync-connect 0)
  (eglot-extend-to-xref t)
  ;; Emacs 31: inline "code action available" hints (eldoc-hint/fringe/margin).
  ;; Some servers make them noisy; keep just the eldoc hint.
  (eglot-code-action-indications '(eldoc-hint))
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

;; setopt (not setq) so the custom setter of treesit-enabled-modes runs.
(setopt treesit-auto-install-grammar 'always ;; Fetch and build missing grammars automatically
        treesit-enabled-modes t)             ;; Prefer every built-in *-ts-mode

(use-package org
  :ensure nil
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture))
  :init
  ;; Org gives `<' paren syntax (for timestamps), so electric-pair completes
  ;; it to <> and org-tempo's `<s TAB' leaves a stray `>'. Inhibit pairing
  ;; of `<' in org buffers only.
  (defun start/org-no-angle-pair ()
    (setq-local electric-pair-inhibit-predicate
                (let ((oldp electric-pair-inhibit-predicate))
                  (lambda (c) (or (char-equal c ?<) (funcall oldp c))))))
  :custom
  (org-edit-src-content-indentation 2) ;; Indent src block contents by 2 spaces.
  (org-return-follows-link t)          ;; RET follows links (TOC, URLs, etc.)

  ;; Notes/agenda/capture
  (org-directory "~/org/")
  (org-default-notes-file (expand-file-name "inbox.org" org-directory))
  (org-agenda-files (list org-directory))  ;; Every .org file in ~/org is agenda material
  (org-capture-templates
   '(("t" "Todo" entry (file+headline org-default-notes-file "Tasks")
      "* TODO %?\n  %U\n  %a")           ;; %a links back to where you captured from
     ("n" "Note" entry (file+headline org-default-notes-file "Notes")
      "* %?\n  %U")))
  (org-log-done 'time)                     ;; Timestamp when a TODO flips to DONE

  :hook
  (org-mode . org-indent-mode)
  (org-mode . start/org-no-angle-pair)
  :config
  (make-directory org-directory t))  ;; Ensure ~/org exists so capture/agenda just work

(use-package markdown-mode
  :mode (("\\.md\\'"  . gfm-mode)
         ("\\.mdx\\'" . gfm-mode))
  :custom
  (markdown-command "pandoc")
  (markdown-fontify-code-blocks-natively t)
  (markdown-header-scaling t)
  (markdown-italic-underscore t))

(add-hook 'elixir-ts-mode-hook
          (lambda ()
            (push '(">=" . ?\u2265) prettify-symbols-alist)  ;; ≥
            (push '("<=" . ?\u2264) prettify-symbols-alist)  ;; ≤
            (push '("!=" . ?\u2260) prettify-symbols-alist)  ;; ≠
            (push '("==" . ?\u2A75) prettify-symbols-alist)  ;; ⩵
            (push '("=~" . ?\u2245) prettify-symbols-alist)  ;; ≅
            (push '("<-" . ?\u2190) prettify-symbols-alist)  ;; ←
            (push '("->" . ?\u2192) prettify-symbols-alist)  ;; →
            (push '("|>" . ?\u25B7) prettify-symbols-alist)  ;; ▷
            (prettify-symbols-mode 1)))

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

;; Sidebar layout for agent-shell. Was only recorded in custom-vars.el
;; (via a manual package-vc-install); declared here so a fresh machine gets it.
(use-package agent-shell-sidebar
  :vc (:url "https://github.com/cmacrae/agent-shell-sidebar")
  :defer t)

(use-package ghostel
  :bind (("C-x m" . ghostel)                 ;; Open a terminal
         :map ghostel-semi-char-mode-map
         ("C-s" . consult-line)              ;; Search the terminal buffer
         ("M-<backspace>" . ghostel-backward-kill-word)
         ("M-p" . (lambda () (interactive) (ghostel-send-key "p" "ctrl")))
         ("M-n" . (lambda () (interactive) (ghostel-send-key "n" "ctrl"))))
  :config
  ;; A terminal at project root is available on `C-x p m'. We don't add it to
  ;; `project-switch-commands' because that's set to a single command
  ;; (`consult-project-extra-find') so switching a project jumps straight into
  ;; the file finder -- there's no dispatch menu to append to.
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
  ;; if-let is obsolete since Emacs 31; if-let* is the same thing.
  (if-let* ((proj (project-current))) (project-root proj) default-directory))

(defun start/test--quote (s)
  "Shell-quote S, but leave empty strings empty (missing token, not '')."
  (if (string-empty-p s) "" (shell-quote-argument s)))

(defun start/test--resolve-cmd (cmd)
  (let* ((file  (start/test--quote (or (buffer-file-name) "")))
         (root  (start/test--quote (start/test--project-root)))
         (tname (start/test--quote (or (start/test--name-at-point) "")))
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
  ;; Fallbacks, tried in reverse order of addition (dict last).
  (add-to-list 'completion-at-point-functions #'cape-dict)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  :config
  ;; Capfs are exclusive: the first one with candidates wins, so a bare
  ;; cape-dabbrev would shadow keyword/snippet completion in most buffers.
  ;; Merge the three prog-buffer sources into one candidate list instead.
  ;; (Eglot buffers replace this stack entirely; see the Eglot section.)
  (add-to-list 'completion-at-point-functions
               (cape-capf-super #'cape-dabbrev #'cape-keyword #'yasnippet-capf)))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  ;; Without this, Emacs's built-in per-category defaults (buffer, unicode-name,
  ;; ...) take precedence over completion-styles and bypass orderless there.
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package vertico
  :init
  (vertico-mode))

;; (savehist-mode is enabled in Good Defaults.)

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
  ;; Project root comes from project.el (`consult-project-function' defaults
  ;; to `project-current'); no override needed now that projectile is gone.
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

(use-package speedbar
  :ensure nil
  :custom
  (speedbar-window-default-width 25)  ;; Emacs 31: side-window width...
  (speedbar-window-max-width 25)      ;; ...and cap so it doesn't fight other windows
  (speedbar-show-unknown-files t)     ;; Show all files, not just "supported" ones
  :bind ("C-x t s" . speedbar-window))

(use-package diminish)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :ensure nil
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
  :diminish
  :custom
  (eldoc-help-at-pt t)) ;; Emacs 31: show help-at-point (flymake etc.) via eldoc

(use-package gcmh
  :diminish gcmh-mode
  :hook (after-init . gcmh-mode)
  :custom
  (gcmh-idle-delay 5)
  (gcmh-high-cons-threshold (* 16 1024 1024)))
