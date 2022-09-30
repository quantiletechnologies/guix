;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2016, 2017, 2018 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2020 Michael Rohleder <mike@rohleder.de>
;;; Copyright © 2021 Marius Bakke <marius@gnu.org>
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

(define-module (gnu packages file)
  #:use-module (gnu packages)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public file
  (package
    (name "file")
    (version "5.39")
    (source (origin
              (method url-fetch)
              (uri (string-append "ftp://ftp.astron.com/pub/file/file-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1lgs2w2sgamzf27kz5h7pajz7v62554q21fbs11n4mfrfrm2hpgh"))))
   (build-system gnu-build-system)

   ;; When cross-compiling, this package depends upon a native install of
   ;; itself.
   (native-inputs (if (%current-target-system)
                      `(("self" ,this-package))
                      '()))

   (properties
    `((release-monitoring-url . "http://ftp.astron.com/pub/file/")))
   (synopsis "File type guesser")
   (description
    "The file command is a file type guesser, a command-line tool that tells
you in words what kind of data a file contains.  It does not rely on filename
extensions to tell you the type of a file, but looks at the actual contents
of the file.  This package provides the libmagic library.")
   (license bsd-2)
   (home-page "https://www.darwinsys.com/file/")))

(define-public file-next
  (package
    (inherit file)
    (version "5.41")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://ftp.astron.com/pub/file/file-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0gv027jgdr0hdkw7m9ck0nwhq583f4aa7vnz4dzdbxv4ng3k5r8k"))))))
