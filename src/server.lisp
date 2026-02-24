(defpackage #:wakaba-web.server
  (:nicknames #:wkb.server)
  (:use #:cl)
  (:export #:*server*
           #:start-server
           #:stop-server
           #:restart-server
           ))
(in-package #:wakaba-web.server)

(defparameter *server* nil)

(defun start-server (&key (server :woo) (address "0.0.0.0") (port 5000) (use-thread t))
  (when *server*
      (format *error-output* "*server* is already running.")
      (return-from start-server :fail))
  (when (null wkb.route:*router*)
    (format *error-output* "*router* is nil. Set wkb.route:*router* before start-server.~%")
    (return-from start-server :fail))
  (handler-case
      (let ((instance (clack:clackup wkb.route:*app*
                                     :server server
                                     :address address
                                     :port port
                                     :debug wkb.config:*debug-mode*
                                     :use-thread use-thread)))
        (if instance
            (progn
              (setf *server* instance)
              :success)
            (progn
              (setf *server* nil)
              :fail)))
    (error (e)
      (format *error-output* "~A~%" e)
      (setf *server* nil)
      :fail)))

(defun stop-server ()
  (unless *server*
    (format *error-output* "Server is already stopped.")
    (return-from stop-server :fail))
  (handler-case
      (progn
        (clack:stop *server*)
        (setf *server* nil)
        :success)
    (error (e)
      (format *error-output* "~A~%" e)
      :fail)))

(defun restart-server (&key (server :woo) (address "0.0.0.0") (port 5000) (use-thread t))
  (when *server*
    (unless (eq (stop-server) :success)
      (return-from restart-server :fail)))
  (start-server :server server
                :address address
                :port port
                :use-thread use-thread))
