;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 John Darrington <jmd@gnu.org>
;;; Copyright © 2018–2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2022 Efraim Flashner <efraim@flashner.co.il>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages ncdu)
  #:use-module (gnu packages)
  #:use-module (gnu packages ncurses)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages zig))

(define-public ncdu
  (package
    (name "ncdu")
    (version "1.17")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://dev.yorhel.nl/download/ncdu-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1wfvdajln0iy7364nxkg4bpgdv8l3b6a9bnkhy67icqsxnl4a1w1"))))
    (build-system gnu-build-system)
    (inputs (list ncurses))
    (synopsis "Ncurses-based disk usage analyzer")
    (description
     "Ncdu is a disk usage analyzer with an ncurses interface, aimed to be
run on a remote server where you don't have an entire graphical setup, but have
to do with a simple SSH connection.  ncdu aims to be fast, simple and easy to
use, and should be able to run in any minimal POSIX-like environment with
ncurses installed.")
    (license (x11-style
              (string-append "https://g.blicky.net/ncdu.git/plain/COPYING?id=v"
                             version)))
    (home-page "https://dev.yorhel.nl/ncdu")))

(define-public ncdu-2
  (package
    (inherit ncdu)
    (name "ncdu2")      ; To destinguish it from the C based version.
    (version "2.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://dev.yorhel.nl/download/ncdu-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0hfimrr7z9zrfkiyj09i8nh4a1rjn7d00y9xzpc7mkyqpkvghjjy"))))
    (arguments
     (list
       #:make-flags
       #~(list (string-append "PREFIX=" #$output)
               (string-append "CC=" #$(cc-for-target)))
       #:phases
       #~(modify-phases %standard-phases
           (delete 'configure)      ; No configure script.
           (add-before 'build 'pre-build
             (lambda _
               (setenv "ZIG_GLOBAL_CACHE_DIR"
                       (mkdtemp "/tmp/zig-cache-XXXXXX"))))
           (add-after 'build 'build-manpage
             (lambda _
               (delete-file "ncdu.1")
               (invoke "make" "doc")))
           (replace 'check
             (lambda* (#:key tests? #:allow-other-keys)
               (when tests?
                 (invoke "zig" "test" "build.zig")))))))
    (native-inputs
     (list perl zig))
    (properties `((upstream-name . "ncdu")))))
