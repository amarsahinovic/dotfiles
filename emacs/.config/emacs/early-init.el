;;; early-init.el --- Loaded before the package system and UI -*- lexical-binding: t; -*-

;; Maximize the GC threshold during startup; gcmh takes over at runtime.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)

;; Skip regex matching against `file-name-handler-alist' on every load/require
;; during startup, then restore it so TRAMP, compressed files, etc. keep working.
(defvar start/--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist start/--file-name-handler-alist
                  ;; Hand a sane threshold back before gcmh (deferred) kicks in.
                  gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

;; Disable UI chrome by setting frame parameters directly so the bars are
;; never drawn (faster than toggling the modes after the frame exists).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

;; Paint the first frame in the theme's colours (ef-owl bg-main/fg-main)
;; before the theme loads, so there's no white flash at startup. Initial frame
;; only: later frames take their colours from whatever theme is active.
(push '(background-color . "#292c2f") initial-frame-alist)
(push '(foreground-color . "#d0d0d0") initial-frame-alist)

;; Startup / redisplay performance.
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      auto-mode-case-fold nil
      load-prefer-newer t
      read-process-output-max (* 2 1024 1024)
      inhibit-compacting-font-caches t)

;; Native-comp: compile asynchronously, don't nag about warnings.
;; Emacs 31: pause async native-comp jobs while on battery (no-op on desktop).
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-async-on-battery-power nil)

;; package.el stays enabled (this config uses it). We disable
;; `package-quickstart' HERE — it must be set before `package-activate-all'
;; runs (between early-init and init), otherwise startup loads a stale
;; quickstart file and newly installed packages fail to activate. With it nil,
;; package.el scans elpa/ normally. Do NOT set `package-enable-at-startup' nil.
(setq package-quickstart nil)
