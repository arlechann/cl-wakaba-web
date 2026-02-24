# wakaba-web

Common Lisp 製の Web フレームワークです。  

テンプレートエンジンには Djula を採用しています。

## インストール

Quicklisp 経由で読み込む場合:

```lisp
(ql:quickload :wakaba-web)
```

ローカル開発環境で読み込む場合:

```lisp
(asdf:load-system :wakaba-web)
```

## 使用例

```lisp
(defpackage #:example.app
  (:use #:cl)
  (:import-from #:wkb.route #:defroute #:clear-routes)
  (:import-from #:wkb.server #:start-server))
(in-package #:example.app)

;; 既存ルートをクリア
(clear-routes)

;; GET /hello
(defroute "/hello" ()
  '(200 (:content-type "text/plain; charset=utf-8") ("hello, wakaba-web")))

;; サーバ起動 (http://127.0.0.1:5000)
(start-server :address "127.0.0.1" :port 5000)
```

メソッド指定付きルートの例:

```lisp
(defroute (:post "/submit") ()
  '(200 (:content-type "text/plain; charset=utf-8") ("submitted")))
```

### presenter

`wkb.controller:make-presenter` で presenter を生成し、`wkb.controller:presenter-send` でレスポンスを作成します。

```lisp
;; text
(wkb.controller:presenter-send
 (wkb.controller:make-presenter :text)
 "hello")

;; json
(wkb.controller:presenter-send
 (wkb.controller:make-presenter :json)
 '(:message "ok"))
```

HTML の場合は `wkb.view:make-html-view` で Djula テンプレートを指定して使います。

```lisp
(let ((view (wkb.view:make-html-view #P"./tmp/tests/template/hello.html")))
  (wkb.controller:presenter-send
   (wkb.controller:make-presenter :html :view view)
   '(:name "alice")))
```

## テスト

```bash
make test
```

## Author

- arlechann (dragnov3728@gmail.com)

## License

CC0-1.0
