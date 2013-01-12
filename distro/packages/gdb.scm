;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Ludovic Courtès <ludo@gnu.org>
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

(define-module (distro packages gdb)
  #:use-module (distro packages ncurses)
  #:use-module (distro packages readline)
  #:use-module (distro packages dejagnu)
  #:use-module (distro packages texinfo)
  #:use-module (distro packages multiprecision)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public gdb
  (package
    (name "gdb")
    (version "7.5")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/gdb/gdb-"
                                 version ".tar.bz2"))
             (sha256
              (base32
               "0chrws5ga90b50kp06yll6zy42fhnx9yr87r4i7swsc369fc8y6i"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-after
                 'configure 'post-configure
                 (lambda _
                   (patch-makefile-SHELL "gdb/gdbserver/Makefile.in"))
                 %standard-phases)))
    (inputs
     `(;; ("expat" ,expat)
       ("mpfr" ,mpfr)
       ("gmp" ,gmp)
       ("readline" ,readline)
       ("ncurses" ,ncurses)
       ;; ("python" ,python)    ; TODO: Add dependency on Python.
       ("texinfo" ,texinfo)
       ("dejagnu" ,dejagnu)))
    (home-page "http://www.gnu.org/software/gdb/")
    (synopsis "GDB, the GNU Project debugger")
    (description
     "GDB, the GNU Project debugger, allows you to see what is going
on `inside' another program while it executes -- or what another
program was doing at the moment it crashed.")
    (license gpl3+)))
