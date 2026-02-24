(defsystem "wakaba-web"
  :version "0.0.1"
  :author "arlechann"
  :mailto "dragnov3728@gmail.com"
  :license "CC0-1.0"
  :depends-on (:uuid
               :clack
               :ningle
               :jonathan
               :djula
               :alexandria
               :list-validate)
  :components ((:module "src"
                :serial t
                :components
                ((:file "utility")
                 (:file "config")
                 (:file "model")
                 (:file "view")
                 (:file "controller")
                 (:file "route")
                 (:file "server"))))
  :description ""
  :in-order-to ((test-op (test-op "wakaba-web/tests"))))

(defsystem "wakaba-web/tests"
  :author "arlechann"
  :license "CC0-1.0"
  :depends-on (:wakaba-web
               :rove)
  :components ((:module "tests"
                :components
                ((:file "config")
                 (:file "utility")
                 (:file "model")
                 (:file "view")
                 (:file "controller")
                 (:file "route")
                 (:file "server"))))
  :description "Test system for wakaba-web"
  :perform (test-op (op c) (symbol-call :rove :run c)))
