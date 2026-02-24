(defpackage wkb/tests/model
  (:use :cl
        :rove))
(in-package :wkb/tests/model)

(defclass test-model ()
  ((id :initarg :id :accessor test-model-id)))

(defmethod wkb.model:to-plist ((model test-model))
  (list :id (test-model-id model)))

(deftest make-id-returns-string
  (testing "make-id は文字列を返す"
    (let ((value (wkb.model:make-id)))
      (ok (stringp value))
      (ok (> (length value) 0)))))

(deftest to-plist-specialization
  (testing "to-plist のメソッドを拡張できる"
    (ok (equal (wkb.model:to-plist (make-instance 'test-model :id "id-1"))
               '(:id "id-1")))))
