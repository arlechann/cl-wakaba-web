(defpackage wkb/tests/route
  (:use :cl
        :rove))
(in-package :wkb/tests/route)

(deftest app-delegates-to-router
  (testing "*app* は *router* に委譲する"
    (let ((wkb.route:*router* (lambda (_env)
                                (declare (ignore _env))
                                '(200 (:content-type "text/plain; charset=utf-8") ("ok")))))
      (ok (equal '(200 (:content-type "text/plain; charset=utf-8") ("ok"))
                 (funcall wkb.route:*app* nil))))))

(deftest app-wraps-router-error
  (testing "*app* は *router* の例外を捕捉して 500 を返す"
    (let ((wkb.route:*router* (lambda (_env)
                                (declare (ignore _env))
                                (error "router failed"))))
      (let ((res (funcall wkb.route:*app* nil)))
        (ok (= 500 (first res)))
        (ok (equal "text/plain; charset=utf-8"
                   (getf (second res) :content-type)))))))

(deftest defroute-registers-get-route
  (testing "defroute は GET ルートを登録できる"
    (let ((wkb.route:*router* (make-instance 'ningle:<app>)))
      (wkb.route:defroute "/health" ()
        "ok")
      (let ((handler (ningle:route wkb.route:*router* "/health")))
        (ok (functionp handler))
        (ok (equal "ok" (funcall handler nil)))))))

(deftest defroute-registers-method-route
  (testing "defroute は HTTP メソッド付きルートを登録できる"
    (let ((wkb.route:*router* (make-instance 'ningle:<app>)))
      (wkb.route:defroute (:post "/submit") ()
        "created")
      (let ((handler (ningle:route wkb.route:*router* "/submit" :method :post)))
        (ok (functionp handler))
        (ok (equal "created" (funcall handler nil)))))))

(deftest defroute-registers-all-method-route
  (testing "defroute は :all でメソッド無指定ルートを登録できる"
    (let ((wkb.route:*router* (make-instance 'ningle:<app>)))
      (wkb.route:defroute (:all "/all") ()
        "ok")
      (let ((handler (ningle:route wkb.route:*router* "/all")))
        (ok (functionp handler))
        (ok (equal "ok" (funcall handler nil)))))))

(deftest defroute-accepts-declare
  (testing "defroute 本体先頭で declare を使える"
    (let ((wkb.route:*router* (make-instance 'ningle:<app>)))
      (wkb.route:defroute "/declare" (params)
        (declare (ignore params))
        "ok")
      (let ((handler (ningle:route wkb.route:*router* "/declare")))
        (ok (functionp handler))
        (ok (equal "ok" (funcall handler nil)))))))

(deftest defroute-invalid-path-spec
  (testing "defroute は不正な path-spec を拒否する"
    (ok (handler-case
            (progn
              (macroexpand-1 '(wkb.route:defroute (:post "/bad" :extra) () "x"))
              nil)
          (error () t)))))

(deftest defroute-invalid-params
  (testing "defroute は params がリストでない場合にエラー"
    (ok (handler-case
            (progn
              (macroexpand-1 '(wkb.route:defroute "/bad" params "x"))
              nil)
          (error () t)))))

(deftest defroute-invalid-method
  (testing "defroute は未対応HTTPメソッドを拒否する"
    (ok (handler-case
            (progn
              (macroexpand-1 '(wkb.route:defroute (:trace "/bad") () "x"))
              nil)
          (error () t)))))
