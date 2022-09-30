;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2020 Mathieu Othacehe <m.othacehe@gmail.com>
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

(define-module (gnu image)
  #:use-module (guix platform)
  #:use-module (guix records)
  #:use-module (guix diagnostics)
  #:use-module (guix i18n)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:export (partition
            partition?
            partition-device
            partition-size
            partition-offset
            partition-file-system
            partition-file-system-options
            partition-label
            partition-uuid
            partition-flags
            partition-initializer

            image
            image?
            image-name
            image-format
            image-platform
            image-size
            image-operating-system
            image-partition-table-type
            image-partitions
            image-compression?
            image-volatile-root?
            image-shared-store?
            image-shared-network?
            image-substitutable?

            image-type
            image-type?
            image-type-name
            image-type-constructor

            os->image
            os+platform->image))


;;;
;;; Partition record.
;;;

(define-record-type* <partition> partition make-partition
  partition?
  (device               partition-device (default #f))
  (size                 partition-size)
  (offset               partition-offset (default 0))
  (file-system          partition-file-system (default "ext4"))
  (file-system-options  partition-file-system-options
                        (default '()))
  (label                partition-label (default #f))
  (uuid                 partition-uuid (default #f))
  (flags                partition-flags (default '()))
  (initializer          partition-initializer (default #f))) ;gexp | #f


;;;
;;; Image record.
;;;

(define-syntax-rule (define-set-sanitizer name field set)
  "Define NAME as a procedure or macro that raises an error if passed a value
that is not in SET, mentioning FIELD in the error message."
  (define-with-syntax-properties (name (value properties))
    (unless (memq value 'set)
      (raise
       (make-compound-condition
        (condition
         (&error-location
          (location (source-properties->location properties))))
        (formatted-message (G_ "~s: invalid '~a' value") value 'field))))
    value))

(define-set-sanitizer validate-image-format format
  (disk-image compressed-qcow2 docker iso9660))
(define-set-sanitizer validate-partition-table-type partition-table-type
  (mbr gpt))

(define-record-type* <image>
  image make-image
  image?
  (name               image-name ;symbol
                      (default #f))
  (format             image-format                ;symbol
                      (sanitize validate-image-format))
  (platform           image-platform ;<platform>
                      (default #f))
  (size               image-size  ;size in bytes as integer
                      (default 'guess))
  (operating-system   image-operating-system  ;<operating-system>
                      (default #f))
  (partition-table-type image-partition-table-type ; 'mbr or 'gpt
                      (default 'mbr)
                      (sanitize validate-partition-table-type))
  (partitions         image-partitions ;list of <partition>
                      (default '()))
  (compression?       image-compression? ;boolean
                      (default #t))
  (volatile-root?     image-volatile-root? ;boolean
                      (default #t))
  (shared-store?      image-shared-store? ;boolean
                      (default #f))
  (shared-network?    image-shared-network? ;boolean
                      (default #f))
  (substitutable?     image-substitutable? ;boolean
                      (default #t)))


;;;
;;; Image type.
;;;

(define-record-type* <image-type>
  image-type make-image-type
  image-type?
  (name           image-type-name) ;symbol
  (constructor    image-type-constructor)) ;<operating-system> -> <image>


;;;
;;; Image creation.
;;;

(define* (os->image os #:key type)
  (let ((constructor (image-type-constructor type)))
    (constructor os)))

(define* (os+platform->image os platform #:key type)
  (image
   (inherit (os->image os #:type type))
   (platform platform)))
