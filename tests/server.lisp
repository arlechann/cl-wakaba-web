(defpackage wkb/tests/server
  (:use :cl
        :rove))
(in-package :wkb/tests/server)

(defmacro with-stubbed-function ((name fn) &body body)
  `(let ((orig (symbol-function ',name)))
     (unwind-protect
          (progn
            (setf (symbol-function ',name) ,fn)
            ,@body)
       (setf (symbol-function ',name) orig))))

(deftest start-server-success
  (testing "start-server は clack:clackup の戻り値を *server* に設定する"
    (let ((wkb.server:*server* nil)
          (wkb.route:*router* (lambda (_env)
                                (declare (ignore _env))
                                '(200 (:content-type "text/plain") ("ok"))))
          (called nil))
      (with-stubbed-function (clack:clackup
                              (lambda (app &key server address port debug use-thread)
                                (setf called (list app server address port debug use-thread))
                                :mock-server))
        (ok (eq :success
                (wkb.server:start-server :server :woo :address "127.0.0.1" :use-thread nil)))
        (ok (equal wkb.server:*server* :mock-server))
        (ok (functionp (first called)))
        (ok (equal (rest called)
                   (list :woo "127.0.0.1" 5000 wkb.config:*debug-mode* nil)))))))

(deftest start-server-when-already-running
  (testing "start-server は起動済みなら何もしない"
    (let ((wkb.server:*server* :already)
          (wkb.route:*router* (lambda (_env)
                                (declare (ignore _env))
                                nil))
          (*error-output* (make-string-output-stream))
          (called nil))
      (with-stubbed-function (clack:clackup
                              (lambda (&rest _)
                                (declare (ignore _))
                                (setf called t)
                                :unexpected))
        (ok (eq :fail (wkb.server:start-server)))
        (ok (equal wkb.server:*server* :already))
        (ok (null called))))))

(deftest stop-server-invokes-clack-stop
  (testing "stop-server は clack:stop を呼び、*server* を nil にする"
    (let ((wkb.server:*server* :running)
          (stopped nil))
      (with-stubbed-function (clack:stop
                              (lambda (server)
                                (setf stopped server)
                                t))
        (ok (eq :success (wkb.server:stop-server)))
        (ok (equal stopped :running))
        (ok (null wkb.server:*server*))))))

(deftest restart-server-stops-and-starts
  (testing "restart-server は stop/start を連続実行する"
    (let ((wkb.server:*server* :old)
          (wkb.route:*router* (lambda (_env)
                                (declare (ignore _env))
                                nil))
          (stopped nil))
      (with-stubbed-function (clack:stop
                              (lambda (server)
                                (setf stopped server)
                                t))
        (with-stubbed-function (clack:clackup
                                (lambda (&rest _)
                                  (declare (ignore _))
                                  :new))
          (ok (eq :success (wkb.server:restart-server)))
          (ok (equal stopped :old))
          (ok (equal wkb.server:*server* :new)))))))
