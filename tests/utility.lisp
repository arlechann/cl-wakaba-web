(defpackage wkb/tests/utility
  (:use :cl
        :rove))
(in-package :wkb/tests/utility)

(deftest make-uuid-returns-string
  (testing "make-uuid は UUID 文字列を返す"
    (let ((value (wkb.utility:make-uuid)))
      (ok (stringp value))
      (ok (> (length value) 0))
      (ok (not (null (find #\- value)))))))

(deftest merge-plist-prefers-second
  (testing "merge-plist は同じキーで第2引数を優先する"
    (ok (equal
         (wkb.utility:merge-plist '(:a 1 :b 2)
                                  '(:b 20 :c 30))
         '(:a 1 :b 20 :c 30)))))

(deftest merge-plist-respects-test
  (testing "merge-plist は :test でキー比較方法を切り替えられる"
    (let* ((k1 (copy-seq "a"))
           (k2 (copy-seq "a")))
      (ok (equal (wkb.utility:merge-plist (list k1 1)
                                          (list k2 2)
                                          :test #'equal)
                 (list k2 2)))
      (ok (equal (wkb.utility:merge-plist (list k1 1)
                                          (list k2 2))
                 (list k1 1 k2 2))))))

(deftest plistp-check
  (testing "plistp は plist 判定を行う"
    (ok (wkb.utility:plistp '(:a 1 :b 2)))
    (ok (wkb.utility:plistp '(a 1 b 2)))
    (ok (wkb.utility:plistp '("a" 1 "b" 2)))
    (ok (null (wkb.utility:plistp '(:a 1 :b))))
    (ok (null (wkb.utility:plistp '(:a . 1))))
    (ok (null (wkb.utility:plistp '(1 "a" :b 2))))))

(deftest list-to-hash-table-groups-in-order
  (testing "list-to-hash-table は順序を維持してグルーピングする"
    (let ((ht (wkb.utility:list-to-hash-table '(1 2 3 4)
                                              :key-fn (lambda (x) (mod x 2))
                                              :value-fn (lambda (x) (* x 10)))))
      (ok (equal (gethash 0 ht) '(20 40)))
      (ok (equal (gethash 1 ht) '(10 30))))))
