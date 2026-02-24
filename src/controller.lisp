(defpackage #:wakaba-web.controller
  (:nicknames #:wkb.controller)
  (:use #:cl)
  (:export #:<presenter>
           #:presenter-send
           #:make-presenter
           #:make-api-response
           #:with-error-handler
           #:with-error-handler/api
           ))
(in-package #:wakaba-web.controller)

(defclass <presenter> () ())

(defgeneric presenter-send (presenter content &key status-code headers))

(defun normalize-api-status (status)
  (let ((normalized
          (cond
            ((stringp status) (string-downcase status))
            ((symbolp status) (string-downcase (symbol-name status)))
            (t nil))))
    (cond
      ((and normalized (string= normalized "ok")) "ok")
      ((and normalized (string= normalized "error")) "error")
      (t nil))))

(defun make-presenter (type &key view location-fn)
  (case type
    (:text (make-instance '<text-presenter>))
    (:html (make-instance '<html-presenter> :view view))
    (:json (make-instance '<json-presenter>))
    (:redirect (make-instance '<redirect-presenter>
                              :location-fn location-fn))
    (t (error "Undefined presenter type: ~S" type))))

(defun make-api-response (status value)
  (let ((normalized-status (normalize-api-status status)))
    (cond
      ((string= normalized-status "ok")
       (list :|status| "ok" :|payload| value))
      ((string= normalized-status "error")
       (list :|status| "error" :|error| value))
      (t
       (error "Unsupported status: ~S" status)))))

(defun api-response-p (content)
  (and (listp content)
       (let ((status (normalize-api-status (getf content :|status| nil))))
         (cond
           ((string= status "ok")
            (and (member :|payload| content :test #'eq)
                 (null (getf content :|error| nil))))
           ((string= status "error")
            (and (member :|error| content :test #'eq)
                 (null (getf content :|payload| nil))))
           (t nil)))))

(defun ensure-api-response (content)
  (if (api-response-p content)
      (let ((status (normalize-api-status (getf content :|status| nil))))
        (if (string= status "ok")
            (make-api-response "ok" (getf content :|payload| nil))
            (make-api-response "error" (getf content :|error| nil))))
      (make-api-response :ok content)))

(defun sanitize-json-content (content)
  (labels ((sanitize-string (text)
             (coerce
              (loop for ch across text
                    for code = (char-code ch)
                    collect (if (or (>= code 32)
                                    (char= ch #\Tab)
                                    (char= ch #\Newline)
                                    (char= ch #\Return))
                                ch
                                #\Space))
              'string))
           (sanitize (value)
             (cond
               ((stringp value)
                (sanitize-string value))
               ((consp value)
                (mapcar #'sanitize value))
               ((hash-table-p value)
                (let ((table (make-hash-table :test #'equal)))
                  (maphash (lambda (k v)
                             (setf (gethash k table) (sanitize v)))
                           value)
                  table))
               (t value))))
    (sanitize content)))

(defun call-with-error-handler (thunk)
  (handler-case
      (funcall thunk)
    (list-validate:validation-parse-error (e)
      (presenter-send (make-presenter :text)
                      (format nil "~A" e)
                      :status-code 400))
    (list-validate:validation-error (e)
      (presenter-send (make-presenter :text)
                      (format nil "~A" e)
                      :status-code 400))
    (error (e)
      (presenter-send (make-presenter :text)
                      (if wkb.config:*debug-mode*
                          (format nil "~A" e)
                          "500 Internal Server Error")
                      :status-code 500))))

(defun call-with-error-handler/api (thunk)
  (handler-case
      (funcall thunk)
    (list-validate:validation-parse-error (e)
      (presenter-send (make-presenter :json)
                      (make-api-response "error" (format nil "~A" e))
                      :status-code 400))
    (list-validate:validation-error (e)
      (presenter-send (make-presenter :json)
                      (make-api-response "error" (format nil "~A" e))
                      :status-code 400))
    (error (e)
      (presenter-send (make-presenter :json)
                      (make-api-response "error"
                                         (if wkb.config:*debug-mode*
                                             (format nil "~A" e)
                                             "Internal Server Error"))
                      :status-code 500))))

(defclass <text-presenter> (<presenter>) ())

(defmethod presenter-send ((presenter <text-presenter>) content &key (status-code 200) headers)
  `(,status-code ,(append headers
                          '(:content-type "text/plain; charset=utf-8"))
                 (,content)))

(defclass <html-presenter> (<presenter>)
  ((view :accessor presenter-view
         :initarg :view
         :type wkb.view:<view>)))

(defmethod presenter-send ((presenter <html-presenter>) content &key (status-code 200) headers)
  `(,status-code ,(append headers
                          '(:content-type "text/html; charset=utf-8"))
                 (,(wkb.view:render-view (presenter-view presenter) content))))

(defclass <json-presenter> (<presenter>) ())

(defmethod presenter-send ((presenter <json-presenter>) content &key (status-code 200) headers)
  `(,status-code ,(append headers
                          '(:content-type "application/json; charset=utf-8"))
                 (,(jojo:to-json (sanitize-json-content
                                  (ensure-api-response content))))))

(defclass <redirect-presenter> (<presenter>)
  ((location-fn :accessor presenter-location-fn
                :initarg :location-fn
                :type function)))

(defmethod presenter-send ((presenter <redirect-presenter>) content &key (status-code 302) headers)
  `(,status-code
    ,(append headers
             `(:content-type "text/html; charset=utf-8"
               :location ,(funcall (presenter-location-fn presenter) content)))
    (,(concatenate 'string
                   "<html><body><a href=\""
                   (funcall (presenter-location-fn presenter) content)
                   "\">移動します</a></body><html>"))))

(defmacro with-error-handler (&body body)
  `(call-with-error-handler
    (lambda ()
      ,@body)))

(defmacro with-error-handler/api (&body body)
  `(call-with-error-handler/api
    (lambda ()
      ,@body)))
