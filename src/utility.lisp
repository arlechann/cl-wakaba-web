(defpackage #:wakaba-web.utility
  (:nicknames #:wkb.utility)
  (:use #:cl)
  (:export #:make-uuid
           #:uuid-to-string
           #:plistp
           #:merge-plist
           #:list-to-hash-table
           ))
(in-package #:wakaba-web.utility)

(defun make-uuid ()
  (uuid-to-string (uuid:make-v4-uuid)))

(defun uuid-to-string (uuid)
  (format nil "~A" uuid))

(defun plistp (obj)
  (and (listp obj)
       (handler-case
           (and (evenp (length obj))
                (loop for cell on obj by #'cddr
                      always (or (symbolp (car cell))
                                 (stringp (car cell)))))
         (type-error ()
           nil))))

(defun merge-plist (p1 p2 &key (test #'eql))
  "2つのプロパティリストをマージする。
P1とP2の両方に同じキーがある場合は、P2の値を優先する。
浅いマージを行い、引数は正しい（偶数長の）plistであることを前提とする。
キー比較にはTESTを使う。"
  (labels ((find-value (indicator plist)
             (loop for cell on plist by #'cddr
                   when (funcall test indicator (car cell))
                     do (return (values (cadr cell) t))
                   finally (return (values nil nil))))
           (rec (p1 p2)
             (if (null p1)
                 p2
                 (let* ((indicator (car p1))
                        (p1-value (cadr p1)))
                   (multiple-value-bind (p2-value exists-p)
                       (find-value indicator p2)
                     (declare (ignore p2-value))
                     (unless exists-p
                       (push p1-value p2)
                       (push indicator p2)))
                   (rec (cddr p1) p2)))))
    (rec p1 (copy-list p2))))

(defun list-to-hash-table (lst &key (key-fn #'identity) (value-fn #'identity) (test #'eql))
  (let ((ht (make-hash-table :test test)))
    (mapc (lambda (item)
            (push (funcall value-fn item) (gethash (funcall key-fn item) ht)))
          lst)
    (maphash (lambda (key values)
               (setf (gethash key ht) (nreverse values)))
             ht)
    ht))
