(defpackage wkb/tests/config
  (:use :cl
        :rove))
(in-package :wkb/tests/config)

(deftest debug-mode-type
  (testing "*debug-mode* は boolean"
    (ok (typep wkb.config:*debug-mode* 'boolean))))

(deftest debug-mode-default
  (testing "*debug-mode* のデフォルトは nil"
    (ok (null wkb.config:*debug-mode*))))

(deftest debug-mode-dynamic-binding
  (testing "動的束縛で切り替えられる"
    (let ((wkb.config:*debug-mode* nil))
      (ok (null wkb.config:*debug-mode*)))))
