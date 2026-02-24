(defpackage wkb/tests/view
  (:use :cl
        :rove))
(in-package :wkb/tests/view)

(defun test-template-path (name)
  (asdf:system-relative-pathname :wakaba-web
                                 (format nil "tmp/tests/template/~A" name)))

(deftest base-view-render-raises-error
  (testing "<view> のデフォルト実装は error を送出する"
    (ok (handler-case
            (progn
              (wkb.view:render-view (make-instance 'wkb.view:<view>) nil)
              nil)
          (error () t)))))

(deftest html-view-renders-template
  (testing "<html-view> はテンプレートを描画できる"
    (let ((path (test-template-path ".wakaba-web-view-test.html")))
      (unwind-protect
           (progn
             (ensure-directories-exist path)
             (with-open-file (out path
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create)
               (write-string "hello template" out))
             (let* ((view (wkb.view:make-html-view path))
                    (rendered (wkb.view:render-view view nil)))
               (ok (typep view 'wkb.view:<html-view>))
               (ok (stringp rendered))
               (ok (search "hello template" rendered))))
        (when (probe-file path)
          (delete-file path))))))

(deftest html-view-invalid-args
  (testing "render-view は plist 以外の引数を拒否する"
    (let ((path (test-template-path ".wakaba-web-view-test-args.html")))
      (unwind-protect
           (progn
             (ensure-directories-exist path)
             (with-open-file (out path
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create)
               (write-string "x" out))
             (let ((view (wkb.view:make-html-view path)))
               (ok (handler-case
                       (progn
                         (wkb.view:render-view view 123)
                         nil)
                     (error () t)))))
        (when (probe-file path)
          (delete-file path))))))

(deftest html-view-renders-with-variables
  (testing "<html-view> はテンプレート変数を受け取って描画できる"
    (let ((path (test-template-path ".wakaba-web-view-test-vars.html")))
      (unwind-protect
           (progn
             (ensure-directories-exist path)
             (with-open-file (out path
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create)
               (write-string "hello {{ name }}" out))
             (let* ((view (wkb.view:make-html-view path))
                    (rendered (wkb.view:render-view view '(:name "alice"))))
               (ok (stringp rendered))
               (ok (not (null (search "hello alice" rendered))))))
        (when (probe-file path)
          (delete-file path))))))
