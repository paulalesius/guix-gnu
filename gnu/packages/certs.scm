;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages certs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages gnuzilla)
  #:use-module (gnu packages openssl)
  #:use-module (gnu packages python))

(define certdata2pem
  (package
    (name "certdata2pem")
    (version "2013")
    (source
    (origin
      (method url-fetch)
        (uri
          "http://pkgs.fedoraproject.org/cgit/ca-certificates.git/plain/certdata2pem.py?id=053dde8a2f5901e97028a58bf54e7d0ef8095a54")
        (sha256
          (base32
            "0zscrm41gnsf14zvlkxhy00h3dmgidyz645ldpda3y3vabnwv8dx"))))
   (build-system trivial-build-system)
   (inputs
     `(("python" ,python-2)))
   (arguments
    `(#:modules ((guix build utils))
      #:builder
        (begin
          (use-modules (guix build utils))
          (let ((bin (string-append %output "/bin")))
            (copy-file (assoc-ref %build-inputs "source") "certdata2pem.py")
            (chmod "certdata2pem.py" #o555)
            (substitute* "certdata2pem.py"
              (("/usr/bin/python")
               (string-append (assoc-ref %build-inputs "python")
                              "/bin/python"))
              ;; Use the file extension .pem instead of .crt.
              (("crt") "pem"))
            (mkdir-p bin)
            (copy-file "certdata2pem.py"
                       (string-append bin "/certdata2pem.py"))))))
   (synopsis "Python script to extract .pem data from certificate collection")
   (description
    "certdata2pem.py is a Python script to transform X.509 certificate
\"source code\" as contained, for example, in the Mozilla sources, into
.pem formatted certificates.")
   (license license:gpl2+)
   (home-page "http://pkgs.fedoraproject.org/cgit/ca-certificates.git/")))

(define-public nss-certs
  (package (inherit nss) ; to reuse the source, version and some metadata
    (name "nss-certs")
    (build-system gnu-build-system)
    (outputs '("out"))
    (native-inputs
     `(("certdata2pem" ,certdata2pem)
       ("openssl" ,openssl)))
    (inputs '())
    (propagated-inputs '())
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (rnrs io ports)
                  (srfi srfi-26)
                  (ice-9 regex))
       #:imported-modules ((guix build gnu-build-system)
                           (guix build utils))
       #:phases
         (alist-cons-after
           'unpack 'install
           (lambda _
             (let ((certsdir (string-append %output "/etc/ssl/certs/"))
                   (trusted-rx (make-regexp "^# openssl-trust=[a-zA-Z]"
                                            regexp/newline)))

               (define (maybe-install-cert file)
                 (let ((cert (call-with-input-file file get-string-all)))
                   (when (regexp-exec trusted-rx cert)
                     (call-with-output-file
                         (string-append certsdir file)
                       (cut display cert <>)))))

               (mkdir-p certsdir)
               (with-directory-excursion "nss/lib/ckfw/builtins/"
                 ;; extract single certificates from blob
                 (system* "certdata2pem.py" "certdata.txt")
                 ;; copy selected .pem files into the output
                 (for-each maybe-install-cert
                           ;; FIXME: Some of the file names are UTF8 (?) and
                           ;; cause an error message such as find-files:
                           ;; ./EBG_Elektronik_Sertifika_Hizmet_Sa??lay??c??s??:2.8.76.175.115.66.28.142.116.2.pem:
                           ;; No such file or directory
                           (find-files "." ".*\\.pem")))

               (with-directory-excursion certsdir
                 ;; create symbolic links for and by openssl
                 ;; Strangely, the call (system* "c_rehash" certsdir)
                 ;; from inside the build dir fails with
                 ;; "Usage error; try -help."
                 ;; This looks like a bug in openssl-1.0.2, but we can also
                 ;; switch into the target directory.
                 (system* "c_rehash" "."))))

           (map (cut assq <> %standard-phases)
                '(set-paths unpack)))))
    (synopsis "CA certificates from Mozilla")
    (description
      "This package provides certificates for Certification Authorities (CA)
taken from the NSS package and thus ultimately from the Mozilla project.")))
