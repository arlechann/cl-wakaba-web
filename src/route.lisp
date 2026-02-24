(defpackage #:wakaba-web.route
  (:nicknames #:wkb.route)
  (:use #:cl)
  (:export #:*router*
           #:*app*
           #:clear-routes
           #:defroute))
(in-package #:wakaba-web.route)

(defparameter *router* (make-instance 'ningle:<app>))

(defun clear-routes () (setf *router* (make-instance 'ningle:<app>)))

(defun make-error-response (env error)
  (declare (ignore env))
  (let ((message (if wkb.config:*debug-mode*
                     (format nil "~A" error)
                     "Internal Server Error")))
    (list 500
          '(:content-type "text/plain; charset=utf-8")
          (list message))))

(defparameter *app* (lambda (env)
                      (handler-case
                          (lack.component:call *router* env)
                        (error (e)
                          (make-error-response env e)))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter +allowed-route-methods+
    '(:get :post :put :patch :delete :options :head :all)))

(defmacro defroute (path-spec params &body body)
  "Define a route.

Form:
  (defroute \"/path\" (params...) ...)
  (defroute (:post \"/path\") (params...) ...)
HTTP method in path-spec must be one of :GET/:POST/:PUT/:PATCH/:DELETE/:OPTIONS/:HEAD/:ALL.
:ALL registers a route without method restriction."
  (let* ((method (and (consp path-spec)
                      (= (length path-spec) 2)
                      (first path-spec)))
         (method-keyword (and method
                              (intern (string-upcase (symbol-name method))
                                      :keyword)))
         (args (if (and method-keyword
                        (not (eq method-keyword :all)))
                   `(:method ,method-keyword)
                   nil))
         (path (if (and (consp path-spec)
                        (= (length path-spec) 2))
                   (second path-spec)
                   path-spec))
         (ignore (gensym)))
    (unless (or (stringp path-spec)
                (and (consp path-spec)
                     (= (length path-spec) 2)))
      (error "Invalid route spec: ~S. Use \"/path\" or (:method \"/path\")."
             path-spec))
    (when (consp path-spec)
      (unless (symbolp (first path-spec))
        (error "HTTP method must be a symbol: ~S" (first path-spec))))
    (when method-keyword
      (unless (member method-keyword +allowed-route-methods+ :test #'eq)
        (error "Unsupported HTTP method: ~S" method)))
    (unless (stringp path)
      (error "Route path must be a string: ~S" path))
    (unless (listp params)
      (error "Route params must be a list: ~S" params))
    (multiple-value-bind (route-body declarations)
        (alexandria:parse-body body
                               :whole `(defroute ,path-spec ,params ,@body))
      `(setf (ningle:route *router* ,path ,@args)
             (lambda (,@params &rest ,ignore)
               (declare (ignore ,ignore))
               ,@declarations
               ,@route-body)))))
