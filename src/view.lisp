(defpackage #:wakaba-web.view
  (:nicknames #:wkb.view)
  (:use #:cl)
  (:export #:<view>
           #:<html-view>
           #:render-view
           #:make-html-view
           ))
(in-package #:wakaba-web.view)

(defclass <view> () ())

(defgeneric render-view (view &optional args))

(defmethod render-view ((view <view>) &optional args)
  (declare (ignore view args))
  (error "render-view is not implemented for this view type"))

(defclass <html-view> (<view>)
  ((template :accessor html-view-template
             :initarg :template)))

(defun make-html-view (template)
  (make-instance '<html-view>
                 :template (djula:compile-template* template)))

(defmethod render-view ((view <html-view>) &optional args)
  (let ((render-args (cond
                       ((null args) nil)
                       ((wkb.utility:plistp args) args)
                       (t (error "html-view args must be a plist, got: ~S" args)))))
    (with-output-to-string (out)
      (apply #'djula:render-template*
             (html-view-template view)
             out
             render-args))))
