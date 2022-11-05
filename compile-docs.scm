;; -*- mode: scheme; geiser-scheme-implementation: guile; compile-command: "guix environment --ad-hoc skribilo guile -- guix repl -- compile-docs.scm"  -*-

;; Note guile is required in the guix env, so that skribilo is put on the load path it also avoid this issue:
;; error: %ref-internal: unbound variable

;; This script compiles the qt-guix documentation, written in Skribilo into an HTML webook.
;; It replaces the standard command line use of the skribilo compiler so that it can be fed
;; into 'guix repl' and as such called in a way that guix channels and modules are on the Guile path.

(define local-repo-clone-path
  (dirname (current-filename)))

(define local-packages-clone-path
  (string-append local-repo-clone-path "/gnu/packages"))

;; You end up circular reference hell with skribilo
;; ice-9/boot-9.scm:1685:16: In procedure raise-exception:
;; no code for module (skribilo)
;; Needs work!
;;(add-to-load-path local-packages-clone-path)

(use-modules (skribilo condition))

(call-with-skribilo-error-catch/exit
  (λ ()
    (apply (module-ref (resolve-interface '(skribilo)) 'skribilo)
           `("--target=html"
             ,(string-append "--source-path=" local-packages-clone-path)
             "--output=index.html"
             ,(string-append local-repo-clone-path "/qtdocs/qt-guix.skb")))))
