;; The default is 800 kilobytes. Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))

(defun start/remove-org-babel-results ()
  "Remove all #+RESULTS blocks in the current org buffer."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^#\\+RESULTS:.*\n" nil t)
      (let ((results-begin (match-beginning 0)))
        ;; Find the end of the results block
        (forward-line 1)
        (let ((results-end (point)))
          ;; Check if there's a drawer or example block
          (cond
           ;; Handle #+begin_example ... #+end_example blocks
           ((looking-at "^#\\+begin_example")
            (when (re-search-forward "^#\\+end_example" nil t)
              (forward-line 1)
              (setq results-end (point))))
           ;; Handle : prefixed results
           ((looking-at "^:")
            (while (and (not (eobp)) (looking-at "^:"))
              (forward-line 1))
            (setq results-end (point)))
           ;; Handle single line results
           ((not (looking-at "^$\\|^#\\|^\\*"))
            (forward-line 1)
            (setq results-end (point))))
          ;; Also remove any trailing blank line after results
          (when (looking-at "^$")
            (forward-line 1)
            (setq results-end (point)))
          ;; Delete the results block
          (delete-region results-begin results-end))))))

(defun start/org-babel-tangle-config ()
  "Automatically tangle our init.org config file and refresh package-quickstart when we save it."
  (interactive)
  (when (and (buffer-file-name)  ;; This handles nil buffer-file-name
             ;; Use file-truename to handle simlinks (eg. when using GNU stow)
             ;; Use equal instead of string-equal as file-truename returns list-like structure
             (equal (file-truename (file-name-directory (buffer-file-name)))
                    (file-truename (expand-file-name user-emacs-directory))))
    ;; Remove results blocks before tangling
    (start/remove-org-babel-results)
    (let ((org-confirm-babel-evaluate nil)
          (warning-minimum-level :error)      ;; Suppress warnings, they are annoying
          (byte-compile-warnings nil))        ;; Disable byte-compile warnings
      (org-babel-tangle)
      (package-quickstart-refresh))))

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
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/"))) ;; For Eat Terminal

(setq package-quickstart t) ;; For blazingly fast startup times, this line makes startup miles faster

;; Refresh the quickstart file after any package install/delete/upgrade so its
;; autoloads don't go stale when upgrading outside of saving init.org.
(dolist (fn '(package-install
              package-delete
              package-upgrade
              package-upgrade-all))
  (when (fboundp fn)
    (advice-add fn :after (lambda (&rest _) (package-quickstart-refresh)))))

(use-package emacs
	:custom
	(menu-bar-mode nil)         ;; Disable the menu bar
	(scroll-bar-mode nil)       ;; Disable the scroll bar
	(tool-bar-mode nil)         ;; Disable the tool bar
	(inhibit-startup-screen t)  ;; Disable welcome screen

  (delete-selection-mode t)   ;; Select text and delete it by typing.
  (electric-indent-mode nil)  ;; Turn off the weird indenting that Emacs does by default.
  (electric-pair-mode t)      ;; Turns on automatic parens pairing

  (blink-cursor-mode nil)     ;; Don't blink cursor
  (global-auto-revert-mode t) ;; Automatically reload file and show changes if the file has changed

  (recentf-mode t) ;; Enable recent file mode (needed by consult-recent-file)

  (display-line-numbers-type 'relative)   ;; Relative line numbers (useful for evil jumps)
  (display-line-numbers-width 4)          ;; Fixed width for line numbers (prevents horizontal shift)
  (global-display-line-numbers-mode t)    ;; Display line numbers
	(column-number-mode t)                  ;; Display column in mode line

  (mouse-wheel-progressive-speed nil) ;; Disable progressive speed when scrolling

	(use-short-answers t)  ;; Use short answers (y instead of yes)

	(indent-tabs-mode nil)
  (tab-width 2)

  (make-backup-files nil) ;; Stop creating ~ backup files
  (auto-save-default nil) ;; Stop creating # auto save files
  :hook
  (prog-mode . (lambda () (hs-minor-mode t))) ;; Enable folding hide/show globally
  :config
  ;; Move customization variables to a separate file and load it, avoid filling up init.el with unnecessary variables
  (setq custom-file (locate-user-emacs-file "custom-vars.el"))
  (load custom-file 'noerror 'nomessage)
  :bind (
         ([escape] . keyboard-escape-quit) ;; Makes Escape quit prompts (Minibuffer Escape)
         ;; You can use the bindings C-+ C-- for zooming in/out. 
				 ;; You can also use CTRL plus the mouse wheel for zooming in/out.
         ("C-+" . text-scale-increase)
         ("C--" . text-scale-decrease)
         ("<C-wheel-up>" . text-scale-increase)
         ("<C-wheel-down>" . text-scale-decrease))

  )

(use-package evil
  :init
  ;; These must be set before evil loads
  (setq evil-want-keybinding nil)    ;; Disable evil bindings in other modes
  (setq evil-want-C-u-scroll t)      ;; C-u scrolls up
  (setq evil-want-C-i-jump nil)      ;; Don't use C-i for jump
  (evil-mode)
  :config
  (setq evil-undo-system 'undo-redo) ;; C-r to redo
  (evil-set-initial-state 'eat-mode 'insert)   ;; Terminal starts in insert mode
  ;; wgrep needs evil-normal-state after activation — evil-collection alone is not enough
  ;; to make evil mode work in wgrep mode
  (with-eval-after-load 'wgrep
    (advice-add 'wgrep-change-to-wgrep-mode :after
                (lambda (&rest _) (evil-normal-state))))
  :bind (:map evil-motion-state-map
              ("SPC" . nil)
              ("RET" . nil)   ;; Let org-return-follows-link work
              ("TAB" . nil)))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

(use-package avy
  :bind ("C-;" . avy-goto-char-timer))

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

  ;; C-c p prefix: Project operations (complement to C-x p)
  ;; Note: C-x p is the built-in project.el prefix with consult-project-extra enhancements
  ;; This C-c p prefix is for projectile-specific commands
  (general-create-definer start/project-keys
    :prefix "C-c p")

  (start/project-keys
    "" '(:ignore t :wk "Project (Projectile)")
    "p" '(projectile-switch-project :wk "Switch project")
    "f" '(projectile-find-file :wk "Find file (projectile with cache)")
    "d" '(projectile-find-dir :wk "Find directory")
    "b" '(projectile-switch-to-buffer :wk "Switch to buffer")
    "c" '(projectile-compile-project :wk "Compile")
    "t" '(projectile-test-project :wk "Run tests")
    "r" '(projectile-run-project :wk "Run project")
    "k" '(projectile-kill-buffers :wk "Kill project buffers")
    "i" '(projectile-invalidate-cache :wk "Invalidate cache")
    "D" '(projectile-dired :wk "Dired at root"))

  ;; Note: C-x p prefix is enhanced by consult-project-extra
  ;; Available commands (built-in + consult enhancements):
  ;; C-x p f - consult-project-extra-find (find file with preview)
  ;; C-x p o - consult-project-extra-find-other-window
  ;; C-x p p - project-switch-project
  ;; C-x p b - project-switch-to-buffer
  ;; C-x p d - project-find-dir
  ;; C-x p g - project-find-regexp
  ;; C-x p r - project-query-replace-regexp
  ;; C-x p s - project-shell
  ;; C-x p e - project-eshell
  ;; C-x p c - project-compile
  ;; C-x p k - project-kill-buffers

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

(use-package nerd-icons
  :if (display-graphic-p))

(use-package nerd-icons-dired
  :hook (dired-mode . (lambda () (nerd-icons-dired-mode t))))

(use-package nerd-icons-ibuffer
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

(add-to-list 'exec-path "~/.local/bin/")
(add-to-list 'exec-path "~/dev/bin/")

(use-package projectile
  :init
  (projectile-mode)
	:config
	(add-hook 'project-find-functions #'project-projectile)
  :custom
  (projectile-run-use-comint-mode t) ;; Interactive run dialog when running projects inside emacs (like giving input)
  (projectile-switch-project-action #'projectile-find-file) ;; Open dired when switching to a project
  (projectile-project-search-path '(("~/dev" . 2)))) ;; Search up to 2 subdirectory levels deep for projects
;; Use Bookmarks for smaller, not standard projects

(use-package eglot
  :ensure nil
  :hook
  (python-ts-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((python-ts-mode python-mode) . ("pyright-langserver"))))

(add-hook 'python-ts-mode-hook
          (lambda () (add-hook 'before-save-hook #'eglot-format nil t)))

;; Configure Elixir LSP only on Linux
(when (eq system-type 'gnu/linux)
  (with-eval-after-load 'eglot
    (setf (alist-get '(elixir-mode elixir-ts-mode heex-ts-mode)
                     eglot-server-programs
                     nil nil #'equal)
          (eglot-alternatives
           '(("expert_linux_amd64" "--stdio") "start_lexical.sh")))))

(use-package sideline-flymake
	:hook (flymake-mode . sideline-mode)
	:custom
	(sideline-flymake-display-mode 'line) ;; Show errors on the current line
	(sideline-backends-right '(sideline-flymake)))

(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package envrc
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

;; Optionally, add any additional mode remappings not covered by defaults
(setq major-mode-remap-alist
      '((yaml-mode . yaml-ts-mode)
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
        (elixir-mode . elixir-ts-mode)
        ))

;; Or if there is no built in mode
(use-package cmake-ts-mode :ensure nil :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))
(use-package go-ts-mode :ensure nil :mode "\\.go\\'")
(use-package go-mod-ts-mode :ensure nil :mode "\\.mod\\'")
(use-package rust-ts-mode :ensure nil :mode "\\.rs\\'")
(use-package tsx-ts-mode :ensure nil :mode "\\.tsx\\'")

(use-package lua-mode
  :mode "\\.lua\\'") ;; Only start in a lua file

(use-package org
  :ensure nil
  :custom
  (org-edit-src-content-indentation 2) ;; Indent src block contents by 2 spaces.
  (org-return-follows-link t)          ;; RET follows links (TOC, URLs, etc.)

  :hook
  (org-mode . org-indent-mode) ;; Indent text
  ;; The following prevents <> from auto-pairing when electric-pair-mode is on.
  ;; Otherwise, org-tempo is broken when you try to <s TAB...
  ;;(org-mode . (lambda ()
  ;;              (setq-local electric-pair-inhibit-predicate
  ;;                          `(lambda (c)
  ;;                             (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))
  )

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  )

(use-package elixir-ts-mode
  :hook
  (elixir-ts-mode . eglot-ensure)
  (heex-ts-mode   . eglot-ensure)
  (elixir-ts-mode . (lambda ()
                      (push '(">=" . ?\u2265) prettify-symbols-alist)  ;; ≥
                      (push '("<=" . ?\u2264) prettify-symbols-alist)  ;; ≤
                      (push '("!=" . ?\u2260) prettify-symbols-alist)  ;; ≠
                      (push '("==" . ?\u2A75) prettify-symbols-alist)  ;; ≝
                      (push '("=~" . ?\u2245) prettify-symbols-alist)  ;; ≈
                      (push '("<-" . ?\u2190) prettify-symbols-alist)  ;; ←
                      (push '("->" . ?\u2192) prettify-symbols-alist)  ;; →
                      (push '("|>" . ?\u25B7) prettify-symbols-alist)  ;; ▷
                      (prettify-symbols-mode 1)))
  (before-save . eglot-format))

(use-package toc-org
  :commands toc-org-enable
  :hook (org-mode . toc-org-mode))

(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode))

(use-package org-tempo
  :ensure nil
  :after org
  :demand t)

(defun start/get-authinfo-secret (host user)
  "Retrieves and returns the secret from .authinfo given a host and user parameters.
Returns nil if no matching entry is found."
  ;; THIS data should be store in ~/.authinfo in the following format:
	;; machine api.mistral.ai login bearer password api-key-goes-here
  (let* ((auth-data (car (auth-source-search :max 1 :host host :user user)))
         (secret-function (plist-get auth-data :secret)))
    (and secret-function (funcall secret-function))))

(defun start/api-mistral-get-bearer-token ()
  "Retrieves and returns the bearer token for Mistral API."
  (interactive)
	(start/get-authinfo-secret "api.mistral.ai" "bearer"))

(defun start/codestral-mistral-get-bearer-token ()
  "Retrieves and returns the bearer token for Mistral Codestrap API."
  (interactive)
	(start/get-authinfo-secret "codestral.mistral.ai" "bearer"))

(use-package gptel
  :ensure t
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

(use-package aidermacs
  :ensure t
  :bind (("C-c a" . aidermacs-transient-menu))
  :custom
  (aidermacs-default-chat-mode 'architect)
  (aidermacs-default-model "mistral/mistral-medium-latest")
  (aidermacs-architect-model "mistral/devstral-medium-2507")
  (aidermacs-editor-model "mistral/devstral-medium-2507")
  (aidermacs-show-diff-after-change nil)
  :config
  ;; Only set API key if available
  (let ((api-key (start/api-mistral-get-bearer-token)))
    (when api-key
      (setenv "MISTRAL_API_KEY" api-key))))

(use-package minuet
  :ensure t
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
  :ensure t
  :defer t)

(use-package acp
  :vc (:url "https://github.com/xenodium/acp.el")
  :defer t)

(use-package agent-shell
  :vc (:url "https://github.com/xenodium/agent-shell")
  :defer t)

(use-package agent-shell-sidebar
  :after agent-shell
  :vc (:url "https://github.com/cmacrae/agent-shell-sidebar"))

(use-package eat
  :hook (eshell-load-hook . eat-eshell-mode))

(use-package magit
  :commands magit-status)

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
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-dict)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

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
  :ensure t
  :after (consult project)
  :bind
  (("C-x p f" . consult-project-extra-find)
   ("C-x p o" . consult-project-extra-find-other-window)))

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
  (setq consult-project-function (lambda (_) (projectile-project-root))))

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
  :bind
  ;; Note that the built-in `describe-function' includes both functions
  ;; and macros. `helpful-function' is functions only, so we provide
  ;; `helpful-callable' as a drop-in replacement.
  ("C-h f" . helpful-callable)
  ("C-h v" . helpful-variable)
  ("C-h k" . helpful-key)
  ("C-h x" . helpful-command)
  )

(use-package treemacs
  :ensure t
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
  :after (treemacs projectile)
  :ensure t)

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once)
  :ensure t)

(use-package treemacs-magit
  :after (treemacs magit)
  :ensure t)

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
  :init (ws-butler-global-mode))

;; Make gc pauses faster by decreasing the threshold.
(setq gc-cons-threshold (* 2 1000 1000))
;; Increase the amount of data which Emacs reads from the process
(setq read-process-output-max (* 1024 1024)) ;; 1mb
