(defpackage #:wakaba-web.config
  (:nicknames #:wkb.config)
  (:use #:cl)
  (:export #:*debug-mode*))
(in-package #:wakaba-web.config)

(defparameter *debug-mode* nil)
