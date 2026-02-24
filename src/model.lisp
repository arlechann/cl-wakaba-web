(defpackage #:wakaba-web.model
  (:nicknames #:wkb.model)
  (:use #:cl
        #:wakaba-web.utility)
  (:export #:make-id
           #:to-plist))
(in-package #:wakaba-web.model)

(defun make-id () (make-uuid))

(defgeneric to-plist (model)
  (:documentation "MODELをplistに変換する。"))
