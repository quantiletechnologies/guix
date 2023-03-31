;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015, 2020 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Leo Famulari <leo@famulari.name>
;;; Copyright © 2020, 2023 Marius Bakke <marius@gnu.org>
;;; Copyright © 2020 Tanguy Le Carrour <tanguy@bioneland.org>
;;; Copyright © 2018, 2021, 2022 Maxim Cournoyer <maxim.cournoyer@gmail.com>
;;; Copyright © 2021 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2021, 2022 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2022 Garek Dyszel <garekdyszel@disroot.org>
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

(define-module (gnu packages python-build)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system python)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages))

;;; Commentary:
;;;
;;; Python packages to build... Python packages.  Since they are bound to be
;;; relied on by many, their dependencies should be kept minimal, and this
;;; module should not depend on other modules containing Python packages.
;;;
;;; Code:

(define-public python-pip
  (package
    (name "python-pip")
    (version "22.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pip" version))
       (sha256
        (base32
         "0jwac0bhfp48w4fqibf1ysrs2grksdv92hwqm7bmdw2jn2fr5l9z"))))
    (build-system python-build-system)
    (arguments
     '(#:tests? #f))          ; there are no tests in the pypi archive.
    (home-page "https://pip.pypa.io/")
    (synopsis "Package manager for Python software")
    (description
     "Pip is a package manager for Python software, that finds packages on the
Python Package Index (PyPI).")
    (license license:expat)))

(define-public python-setuptools
  (package
    (name "python-setuptools")
    (version "64.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "setuptools" version))
       (sha256
        (base32
         "1sllqf0bhsl2yilf1w0xnlz0r4yaksmwaj0ap91zdc6kgbigdjiv"))
       (modules '((guix build utils)))
       (snippet
        ;; TODO: setuptools now bundles the following libraries:
        ;; packaging, pyparsing, six and appdirs. How to unbundle?
        ;; Remove included binaries which are used to build self-extracting
        ;; installers for Windows.
        '(for-each delete-file (find-files "setuptools"
                                           "^(cli|gui).*\\.exe$")))))
    (build-system python-build-system)
    ;; FIXME: Tests require pytest, which itself relies on setuptools.
    ;; One could bootstrap with an internal untested setuptools.
    (arguments (list #:tests? #f))
    (home-page "https://pypi.org/project/setuptools/")
    (synopsis "Library designed to facilitate packaging Python projects")
    (description "Setuptools is a fully-featured, stable library designed to
facilitate packaging Python projects, where packaging includes:
@itemize
@item Python package and module definitions
@item distribution package metadata
@item test hooks
@item project installation
@item platform-specific details.
@end itemize")
    (license (list license:psfl         ;setuptools itself
                   license:expat        ;six, appdirs, pyparsing
                   license:asl2.0       ;packaging is dual ASL2/BSD-2
                   license:bsd-2))))

;; This is the last version with use_2to3 support.
(define-public python-setuptools-57
  (package
    (inherit python-setuptools)
    (version "57.5.0")
    (source (origin
              (inherit (package-source python-setuptools))
              (uri (pypi-uri "setuptools" version))
              (sha256
               (base32
                "091sp8lrin7qllrhhx7y0iiv5gdb1d3l8a1ip5knk77ma1njdlyr"))))))

(define-public python-wheel
  (package
    (name "python-wheel")
    (version "0.37.0")
    (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "wheel" version))
        (sha256
         (base32
          "1bbga5i49rj1cwi4sjpkvfhl1f8vl9lfky2lblsy768nk4wp5vz2"))))
    (build-system python-build-system)
    (arguments
     ;; FIXME: The test suite runs "python setup.py bdist_wheel", which in turn
     ;; fails to find the newly-built bdist_wheel library, even though it is
     ;; available on PYTHONPATH.  What search path is consulted by setup.py?
     '(#:tests? #f))
    (home-page "https://bitbucket.org/pypa/wheel/")
    (synopsis "Format for built Python packages")
    (description
     "A wheel is a ZIP-format archive with a specially formatted filename and
the @code{.whl} extension.  It is designed to contain all the files for a PEP
376 compatible install in a way that is very close to the on-disk format.  Many
packages will be properly installed with only the @code{Unpack} step and the
unpacked archive preserves enough information to @code{Spread} (copy data and
scripts to their final locations) at any later time.  Wheel files can be
installed with a newer @code{pip} or with wheel's own command line utility.")
    (license license:expat)))

;;; XXX: Not really at home, but this seems the best place to prevent circular
;;; module dependencies.
(define-public python-toml
  (package
    (name "python-toml")
    (version "0.10.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "toml" version))
       (sha256
        (base32 "13z6rff86bzdpl094x0vmfvls779931xj90dlbs9kpfm138s3gdk"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f))                     ;no tests suite in release
    (home-page "https://github.com/uiri/toml")
    (synopsis "Library for TOML")
    (description
     "@code{toml} is a library for parsing and creating Tom's Obvious, Minimal
Language (TOML) configuration files.")
    (license license:expat)))

(define-public python-tomli-w
  (package
    (name "python-tomli-w")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tomli_w" version))
       (sha256
        (base32 "1fg13bfq5qy1ym4x77815nhxh1xpfs0drhn9r9464cz00m1l6qzl"))))
    (build-system python-build-system)
    (arguments
     (list
      #:tests? #f                       ;to avoid extra dependencies
      #:phases
      #~(modify-phases %standard-phases
          ;; XXX: PEP 517 manual build copied from python-isort.
          (replace 'build
            (lambda _
              (invoke "python" "-m" "build" "--wheel" "--no-isolation" ".")))
          (replace 'install
            (lambda _
              (let ((whl (car (find-files "dist" "\\.whl$"))))
                (invoke "pip" "--no-cache-dir" "--no-input"
                        "install" "--no-deps" "--prefix" #$output whl)))))))
    (native-inputs (list python-pypa-build python-flit-core))
    (home-page "https://github.com/hukkin/tomli-w")
    (synopsis "Minimal TOML writer")
    (description "Tomli-W is a Python library for writing TOML.  It is a
write-only counterpart to Tomli, which is a read-only TOML parser.")
    (license license:expat)))

(define-public python-pytoml
  (package
    (name "python-pytoml")
    (version "0.1.21")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pytoml" version))
       (sha256
        (base32
         "1rv1byiw82k7mj6aprcrqi2vdabs801y97xhfnrz7kxds34ggv4f"))))
    (build-system python-build-system)
    (home-page "https://github.com/avakar/pytoml")
    (synopsis "Parser for TOML")
    (description "This package provides a Python parser for TOML-0.4.0.")
    (license license:expat)))

(define-public python-six-bootstrap
  (package
    (name "python-six-bootstrap")
    (version "1.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "six" version))
       (sha256
        (base32
         "09n9qih9rpj95q3r4a40li7hk6swma11syvgwdc68qm1fxsc6q8y"))))
    (build-system python-build-system)
    (arguments `(#:tests? #f))          ;to avoid pytest dependency
    (home-page "https://pypi.org/project/six/")
    (synopsis "Python 2 and 3 compatibility utilities")
    (description
     "Six is a Python 2 and 3 compatibility library.  It provides utility
functions for smoothing over the differences between the Python versions with
the goal of writing Python code that is compatible on both Python versions.
Six supports every Python version since 2.5.  It is contained in only one
Python file, so it can be easily copied into your project.")
    (license license:x11)))

(define-public python-tomli
  (package
    (name "python-tomli")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "tomli" version))
       (sha256
        (base32 "1q8lrh9ypa6zpgbc5f7z23p7phzblp4vpxdrpfr1wajhb17w74n2"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f                      ;disabled to avoid extra dependencies
       #:phases
       (modify-phases %standard-phases
         (replace 'build
           (lambda _
             (setenv "PYTHONPATH" (string-append (getcwd) ":"
                                                 (getenv "GUIX_PYTHONPATH")))
             (invoke "python" "-m" "build" "--wheel" "--no-isolation"
                     "--skip-dependency-check")))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (whl (car (find-files "dist" "\\.whl$"))))
               (invoke "pip" "--no-cache-dir" "--no-input"
                       "install" "--no-deps" "--prefix" out whl)))))))
    (native-inputs
     `(("python-flit-core-bootstrap" ,python-flit-core-bootstrap)
       ("python-pypa-build" ,python-pypa-build)
       ("python-six", python-six-bootstrap)))
    (home-page "https://github.com/hukkin/tomli")
    (synopsis "Small and fast TOML parser")
    (description "Tomli is a minimal TOML parser that is fully compatible with
@url{https://toml.io/en/v1.0.0,TOML v1.0.0}.  It is about 2.4 times as fast as
@code{python-toml}.")
    (license license:expat)))

(define-public python-pep517-bootstrap
  (hidden-package
   (package
     (name "python-pep517-bootstrap")
     (version "0.9.1")
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "pep517" version))
        (sha256
         (base32
          "0zqidxah03qpnp6zkg3zd1kmd5f79hhdsfmlc0cldaniy80qddxf"))))
     (build-system python-build-system)
     (arguments
      `(#:tests? #f))                     ;to avoid circular dependencies
     (propagated-inputs
      (list python-toml python-wheel))
     (home-page "https://github.com/pypa/pep517")
     (synopsis "Wrappers to build Python packages using PEP 517 hooks")
     (description
      "Wrappers to build Python packages using PEP 517 hooks.")
     (license license:expat))))

(define-public python-pyparsing
  (package
    (name "python-pyparsing")
    (version "3.0.6")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pyparsing" version))
       (sha256
        (base32 "109b9r802wb472hgmxclljprh5cid0w3p6mk9alba7pg2c0frgfr"))))
    (build-system python-build-system)
    (outputs '("out" "doc"))
    (arguments
     `(#:tests? #f                      ;no test target
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'install-doc
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((doc (string-append (assoc-ref outputs "doc")
                                        "/share/doc/" ,name "-" ,version))
                    (html-doc (string-append doc "/html"))
                    (examples (string-append doc "/examples")))
               (mkdir-p html-doc)
               (mkdir-p examples)
               (for-each
                (lambda (dir tgt)
                  (map (lambda (file)
                         (install-file file tgt))
                       (find-files dir ".*")))
                (list "docs" "htmldoc" "examples")
                (list doc html-doc examples))))))))
    (home-page "https://github.com/pyparsing/pyparsing")
    (synopsis "Python parsing class library")
    (description
     "The pyparsing module is an alternative approach to creating and
executing simple grammars, vs. the traditional lex/yacc approach, or the use
of regular expressions.  The pyparsing module provides a library of classes
that client code uses to construct the grammar directly in Python code.")
    (license license:expat)))

;;; This is the last release compatible with Python 2.
(define-public python-pyparsing-2.4.7
  (package
    (inherit python-pyparsing)
    (version "2.4.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pyparsing" version))
       (sha256
        (base32 "1hgc8qrbq1ymxbwfbjghv01fm3fbpjwpjwi0bcailxxzhf3yq0y2"))))))

(define-public python-packaging-bootstrap
  (package
    (name "python-packaging-bootstrap")
    (version "21.3")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "packaging" version))
       (sha256
        (base32
         "1sygirdrqgv4f1ckh9nhpcw1yfidrh3qjl86wq8vk6nq4wlw8iyx"))))
    (build-system python-build-system)
    (arguments `(#:tests? #f))         ;disabled to avoid extra dependencies
    (propagated-inputs
     (list python-pyparsing python-six-bootstrap))
    (home-page "https://github.com/pypa/packaging")
    (synopsis "Core utilities for Python packages")
    (description "Packaging is a Python module for dealing with Python packages.
It offers an interface for working with package versions, names, and dependency
information.")
    ;; From 'LICENSE': This software is made available under the terms of
    ;; *either* of the licenses found in LICENSE.APACHE or LICENSE.BSD.
    ;; Contributions to this software is made under the terms of *both* these
    ;; licenses.
    (license (list license:asl2.0 license:bsd-2))))

;;; The name 'python-pypa-build' is chosen rather than 'python-build' to avoid
;;; a name clash with python-build from (guix build-system python).
(define-public python-pypa-build
  (package
    (name "python-pypa-build")
    (version "0.7.0")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "build" version))
              (sha256
               (base32
                "17xqija27x4my1yrnk6q2vwln60r39g2dhby9zg2l99qjgbdrahs"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f                      ;to tests in the PyPI release
       #:phases (modify-phases %standard-phases
                  (add-after 'unpack 'use-toml-instead-of-tomli
                    ;; Using toml instead of tomli eases bootstrapping.
                    (lambda _
                      (substitute* "setup.cfg"
                        (("tomli>=.*")
                         "toml\n")))))))
    (propagated-inputs
     `(("python-packaging" ,python-packaging-bootstrap)
       ("python-pep517", python-pep517-bootstrap)
       ("python-toml" ,python-toml)))
    (home-page "https://pypa-build.readthedocs.io/en/latest/")
    (synopsis "Simple Python PEP 517 package builder")
    (description "The @command{build} command invokes the PEP 517 hooks to
build a distribution package.  It is a simple build tool and does not perform
any dependency management.  It aims to keep dependencies to a minimum, in
order to make bootstrapping easier.")
    (license license:expat)))

(define-public python-poetry-core
  (package
    (name "python-poetry-core")
    (version "1.0.7")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "poetry-core" version))
       (sha256
        (base32 "01n2rbsvks7snrq3m1d08r3xz9q2715ajb62fdb6rvqnb9sirhcq"))))
    (build-system python-build-system)
    (home-page "https://github.com/python-poetry/poetry-core")
    (synopsis "Poetry PEP 517 build back-end")
    (description
     "The @code{poetry-core} module provides a PEP 517 build back-end
implementation developed for Poetry.  This project is intended to be
a light weight, fully compliant, self-contained package allowing PEP 517
compatible build front-ends to build Poetry managed projects.")
    (license license:expat)))

;;; This package exists to bootstrap python-tomli.
(define-public python-flit-core-bootstrap
  (package
    (name "python-flit-core-bootstrap")
    (version "3.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "flit" version))
       (sha256
        (base32 "04152qj46sqbnlrj7ch9p7svjrrlpzbk0qr39g2yr0s4f5vp6frf"))))
    (build-system python-build-system)
    (propagated-inputs
     (list python-toml))
    (arguments
     ;; flit-core has a test suite, but it requires Pytest.  Disable it so
     ;; as to not pull pytest as an input.
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (replace 'build
           ;; flit-core requires itself to build.  Luckily, a
           ;; bootstrapping script exists, which does so using just
           ;; the checkout sources and Python.
           (lambda _
             (invoke "python" "flit_core/build_dists.py")))
         (replace 'install
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (whl (car (find-files "." "\\.whl$"))))
               (invoke "pip" "--no-cache-dir" "--no-input"
                       "install" "--no-deps" "--prefix" out whl))))
         ;; The sanity-check phase fails because flit depends on tomli at
         ;; run-time, but this core variant avoids it to avoid a cycle.
         (delete 'sanity-check))))
    (home-page "https://github.com/takluyver/flit")
    (synopsis "Core package of the Flit Python build system")
    (description "This package provides @code{flit-core}, a PEP 517 build
backend for packages using Flit.  The only public interface is the API
specified by PEP 517, @code{flit_core.buildapi}.")
    (license license:bsd-3)))

(define-public python-flit-core
  (package/inherit python-flit-core-bootstrap
    (name "python-flit-core")
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-flit-core-bootstrap)
       (replace "python-toml" python-tomli)))))

(define-public python-flit-scm
  (package
    (name "python-flit-scm")
    (version "1.6.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "flit_scm" version))
              (sha256
               (base32
                "0p3lj2g1643m2dm14kihvfb6gn6jviglhm3dzdpn2c8zpqs17svg"))))
    (build-system python-build-system)
    (arguments
     (list
      #:tests? #f                       ;no test suite
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'relax-setuptools-scm-version
            (lambda _
              (substitute* "pyproject.toml"
                (("setuptools_scm~=6.4")
                 "setuptools_scm>=6.3"))))
          ;; XXX: PEP 517 manual build/install procedures copied from
          ;; python-isort.
          (replace 'build
            (lambda _
              ;; ZIP does not support timestamps before 1980.
              (setenv "SOURCE_DATE_EPOCH" "315532800")
              (invoke "python" "-m" "build" "--wheel" "--no-isolation" ".")))
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((whl (car (find-files "dist" "\\.whl$"))))
                (invoke "pip" "--no-cache-dir" "--no-input"
                        "install" "--no-deps" "--prefix" #$output whl)))))))
    (native-inputs
     (list python-pypa-build
           python-flit-core
           python-setuptools-scm
           python-tomli))
    (propagated-inputs
     (list python-flit-core
           python-setuptools-scm
           python-tomli))
    (home-page "https://gitlab.com/WillDaSilva/flit_scm")
    (synopsis "PEP 518 build backend combining flit_core and setuptools_scm")
    (description "This package provides a PEP 518 build backend that uses
@code{setuptools_scm} to generate a version file from your version control
system, then @code{flit_core} to build the package.")
    (license license:expat)))

(define-public python-setuptools-scm
  (package
    (name "python-setuptools-scm")
    (version "6.3.2")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "setuptools_scm" version))
              (sha256
               (base32 "1wm0i27siyy1yqr9rv7lqvb65agay9051yi8jzmi8dgb3q4ai6m4"))))
    (build-system python-build-system)
    (propagated-inputs
     `(("python-packaging",python-packaging-bootstrap)
       ("python-tomli" ,python-tomli)))
    (home-page "https://github.com/pypa/setuptools_scm/")
    (synopsis "Manage Python package versions in SCM metadata")
    (description
     "Setuptools_scm handles managing your Python package versions in
@dfn{software configuration management} (SCM) metadata instead of declaring
them as the version argument or in a SCM managed file.")
    (license license:expat)))

(define-public python-editables
  (package
    (name "python-editables")
    (version "0.3")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/pfmoore/editables")
                    (commit version)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1gbfkgzmrmbd4ycshm09fr2wd4f1n9gq7s567jgkavhfkn7s2pn1"))))
    (build-system python-build-system)
    (home-page "https://github.com/pfmoore/editables")
    (synopsis "Editable installations")
    (description "This library supports the building of wheels which, when
installed, will expose packages in a local directory on @code{sys.path} in
``editable mode''.  In other words, changes to the package source will be
reflected in the package visible to Python, without needing a reinstall.")
    (license license:expat)))
