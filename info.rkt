#lang info

(define collection "rpn")

(define scribblings
  (list (list "main.scrbl"
              (list)
              (list 'library)
              "rpn")))

(define deps
  (list "base"
        "rebellion"))

(define build-deps
  (list "racket-doc"
        "rackunit-lib"
        "scribble-lib"))

(define test-omit-paths
  (list #rx"\\.scrbl$"))
