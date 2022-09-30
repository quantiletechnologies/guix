;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015, 2017, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2019 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2022 Brendan Tildesley <mail@brendan.scot>
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

(define-module (gnu packages pciutils)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages hurd)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages base))

(define-public hwdata
  (package
    (name "hwdata")
    (version "0.357")                   ;updated monthly
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/vcrhonek/hwdata")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0kvxpdx14w2myqm3dikjvr2mr4j6767y4v5j8v7kffwvcv0ga9gv"))))
    (build-system gnu-build-system)
    (outputs '("out" "iab" "oui" "pci" "pnp" "usb"))
    (arguments
     ;; Tests require pciutils, python, podman. Disable to avoid recursive dep.
     (list
      #:tests? #f
      ;; Do not cross-compile, since the package only contains data.
      #:target #f
      #:configure-flags #~(list (string-append "--datadir=" #$output "/share"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'install
            (lambda _
              (install-file "iab.txt" (string-append #$output:iab "/share/hwdata"))
              (install-file "oui.txt" (string-append #$output:oui "/share/hwdata"))
              (install-file "pci.ids" (string-append #$output:pci "/share/hwdata"))
              (install-file "pnp.ids" (string-append #$output:pnp "/share/hwdata"))
              (install-file "usb.ids" (string-append #$output:usb "/share/hwdata")))))))
    (home-page "https://github.com/vcrhonek/hwdata")
    (synopsis "Hardware identification and configuration data")
    (description "@code{hwdata} contains various hardware identification and
configuration data, such as the @file{pci.ids} and @file{usb.ids} databases.
Each database is contained in a specific package output, such as the
@code{pci} output for @file{pci.ids}, the @code{usb} output for
@file{usb.ids}, etc.")
    (license (list license:gpl2+
                   license:expat)))) ;XFree86 1.0

(define-public pciutils
  (package
    (name "pciutils")
    (version "3.7.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/software/utils/pciutils/pciutils-"
                    version ".tar.xz"))
              (patches (search-patches "pciutils-hurd-configure.patch"))
              (sha256
               (base32
                "1ss0rnfsx8gvqjxaji4mvbhf9xyih4cadmgadbwwv8mnx1xvjh4x"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             ;; There's no 'configure' script, just a raw makefile.
             (substitute* "Makefile"
               ,@(if (%current-target-system)
                     `((("^CROSS_COMPILE=.*$")
                        (string-append "CROSS_COMPILE="
                                       ,(%current-target-system) "-"
                                       "\n"))
                       (("^HOST=.*$")
                        (string-append "HOST="
                                       ,(gnu-triplet->nix-system
                                         (%current-target-system)) "\n"))
                       ;; Disable 'install' strip option, that would fail when
                       ;; we are cross-compiling.
                       (("^STRIP=.*$")
                        "STRIP=\n"))
                     '())
               (("^PREFIX=.*$")
                (string-append "PREFIX := " (assoc-ref outputs "out")
                               "\n"))
               (("^MANDIR:=.*$")
                 ;; By default the thing tries to automatically
                 ;; determine whether to use $prefix/man or
                 ;; $prefix/share/man, and wrongly so.
                (string-append "MANDIR := " (assoc-ref outputs "out")
                               "/share/man\n"))

               (("^SHARED=.*$")
                ;; Build libpciutils.so.
                "SHARED := yes\n")
               (("^ZLIB=.*$")
                ;; Ask for zlib support, for 'pci.ids.gz' decompression.
                "ZLIB := yes\n")

               (("^IDSDIR=.*$")
                ;; Installation directory of 'pci.ids.gz'.
                "IDSDIR = $(SHAREDIR)/hwdata\n"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             ;; Install the commands, library, and .pc files.
             (invoke "make" "install" "install-lib")))

         ,@(if (hurd-target?)
               '((add-after 'unpack 'apply-hurd-patch
                   (lambda* (#:key inputs #:allow-other-keys)
                     (let ((patch (assoc-ref inputs "hurd-patch")))
                       (invoke "patch" "-p1" "--batch" "-i"
                               patch)))))
               '()))

       ;; Make sure programs have an RPATH so they can find libpciutils.so.
       #:make-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                         (assoc-ref %outputs "out") "/lib"))

       ;; No test suite.
       #:tests? #f))
    (native-inputs
     (list which pkg-config))
    (inputs
     `(,@(if (not (hurd-target?))
             `(("kmod" ,kmod))
             '())
       ,@(if (hurd-target?)
             `(("hurd-patch" ,(search-patch "pciutils-hurd-fix.patch")))
             '())
       ("zlib" ,zlib)))
    (home-page "https://mj.ucw.cz/sw/pciutils/")
    (synopsis "Programs for inspecting and manipulating PCI devices")
    (description
     "The PCI Utilities are a collection of programs for inspecting and
manipulating configuration of PCI devices, all based on a common portable
library libpci which offers access to the PCI configuration space on a variety
of operating systems.  This includes the @command{lspci} and @command{setpci}
commands.")
    (license license:gpl2+)))
