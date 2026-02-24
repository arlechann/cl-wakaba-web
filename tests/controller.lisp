(defpackage wkb/tests/controller
  (:use :cl
        :rove))
(in-package :wkb/tests/controller)

(defclass test-view (wkb.view:<view>) ())

(defmethod wkb.view:render-view ((view test-view) &optional args)
  (declare (ignore view))
  (format nil "<p>~A</p>" args))

(deftest make-api-response-shape
  (testing "make-api-response はスキーマに沿った plist を返す"
    (ok (equal (wkb.controller:make-api-response "ok" '(:x 1))
               '(:|status| "ok" :|payload| (:x 1))))
    (ok (equal (wkb.controller:make-api-response "error" "e")
               '(:|status| "error" :|error| "e")))
    (ok (equal (wkb.controller:make-api-response :ok '(:x 1))
               '(:|status| "ok" :|payload| (:x 1))))
    (ok (equal (wkb.controller:make-api-response 'error "e")
               '(:|status| "error" :|error| "e")))))

(deftest text-presenter-send
  (testing "text presenter は text/plain を返す"
    (let ((res (wkb.controller:presenter-send
                (wkb.controller:make-presenter :text)
                "hello")))
      (ok (= 200 (first res)))
      (ok (equal "text/plain; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (equal '("hello") (third res))))))

(deftest html-presenter-send
  (testing "html presenter は view を使って描画する"
    (let ((res (wkb.controller:presenter-send
                (wkb.controller:make-presenter :html
                                               :view (make-instance 'test-view))
                "body")))
      (ok (= 200 (first res)))
      (ok (equal "text/html; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (equal '("<p>body</p>") (third res))))))

(deftest json-presenter-wraps-content
  (testing "json presenter は API レスポンス形式に正規化する"
    (let* ((res (wkb.controller:presenter-send
                 (wkb.controller:make-presenter :json)
                 '(:x 1)))
           (body (first (third res))))
      (ok (= 200 (first res)))
      (ok (equal "application/json; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (not (null (search "\"status\":\"ok\"" body))))
      (ok (not (null (search "\"payload\"" body)))))))

(deftest json-presenter-sanitizes-control-characters
  (testing "json presenter は生の制御文字をサニタイズする"
    (let* ((raw (concatenate 'string "a" (string (code-char 8)) "b"))
           (res (wkb.controller:presenter-send
                 (wkb.controller:make-presenter :json)
                 (list :message raw)))
           (body (first (third res))))
      (ok (= 200 (first res)))
      (ok (not (null (search "\"MESSAGE\":\"a b\"" body))))
      (ok (null (search (string (code-char 8)) body))))))

(deftest with-error-handler-200
  (testing "with-error-handler の正常系は 200 を返す"
    (let ((res (wkb.controller:with-error-handler
                 (wkb.controller:presenter-send
                  (wkb.controller:make-presenter :text)
                  "ok"))))
      (ok (= 200 (first res)))
      (ok (equal '("ok") (third res))))))

(deftest with-error-handler-400
  (testing "with-error-handler は validation-error を 400 に変換する"
    (let ((res (wkb.controller:with-error-handler
                 (error 'list-validate:validation-error
                        :field :id
                        :value "x"
                        :rules '(:integer)))))
      (ok (= 400 (first res)))
      (ok (equal "text/plain; charset=utf-8"
                 (getf (second res) :content-type))))))

(deftest with-error-handler-400-parse-error
  (testing "with-error-handler は validation-parse-error を 400 に変換する"
    (let ((res (wkb.controller:with-error-handler
                 (error 'list-validate:validation-parse-error
                        :field :id
                        :value "x"
                        :rules '(:integer)))))
      (ok (= 400 (first res)))
      (ok (equal "text/plain; charset=utf-8"
                 (getf (second res) :content-type))))))

(deftest with-error-handler-500
  (testing "with-error-handler は汎用エラーを 500 に変換する"
    (let ((wkb.config:*debug-mode* nil))
      (let ((res (wkb.controller:with-error-handler
                   (error "boom"))))
        (ok (= 500 (first res)))
        (ok (equal "text/plain; charset=utf-8"
                   (getf (second res) :content-type)))
        (ok (equal '("500 Internal Server Error") (third res)))))))

(deftest with-error-handler-api-200
  (testing "with-error-handler/api の正常系は 200 を返す"
    (let* ((res (wkb.controller:with-error-handler/api
                  (wkb.controller:presenter-send
                   (wkb.controller:make-presenter :json)
                   '(:value 1))))
           (body (first (third res))))
      (ok (= 200 (first res)))
      (ok (equal "application/json; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (not (null (search "\"status\":\"ok\"" body)))))))

(deftest with-error-handler-api-400
  (testing "with-error-handler/api は validation-error を 400 に変換する"
    (let* ((res (wkb.controller:with-error-handler/api
                  (error 'list-validate:validation-error
                         :field :id
                         :value "x"
                         :rules '(:integer))))
           (body (first (third res))))
      (ok (= 400 (first res)))
      (ok (equal "application/json; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (not (null (search "\"status\":\"error\"" body)))))))

(deftest with-error-handler-api-400-parse-error
  (testing "with-error-handler/api は validation-parse-error を 400 に変換する"
    (let* ((res (wkb.controller:with-error-handler/api
                  (error 'list-validate:validation-parse-error
                         :field :id
                         :value "x"
                         :rules '(:integer))))
           (body (first (third res))))
      (ok (= 400 (first res)))
      (ok (equal "application/json; charset=utf-8"
                 (getf (second res) :content-type)))
      (ok (not (null (search "\"status\":\"error\"" body)))))))

(deftest with-error-handler-api-500
  (testing "with-error-handler/api は汎用エラーを JSON 500 に変換する"
    (let ((wkb.config:*debug-mode* nil))
      (let* ((res (wkb.controller:with-error-handler/api
                    (error "boom")))
             (body (first (third res))))
        (ok (= 500 (first res)))
        (ok (equal "application/json; charset=utf-8"
                   (getf (second res) :content-type)))
        (ok (not (null (search "\"status\":\"error\"" body))))))))
