#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [binary-rpn-operator (-> (-> any/c any/c any/c) rpn-operator?)]
  [empty-rpn-stack rpn-stack?]
  [r+ rpn-operator?]
  [r- rpn-operator?]
  [r* rpn-operator?]
  [r/ rpn-operator?]
  [rpn (-> any/c ... rpn-stack?)]
  [rpn-instruction? predicate/c]
  [rpn-stack? predicate/c]
  [rpn-stack-push (-> rpn-stack? rpn-instruction? rpn-stack?)]
  [rpn-operand (-> any/c rpn-operand?)]
  [rpn-operand? predicate/c]
  [rpn-operand-value (-> rpn-operand? any/c)]
  [rpn-operator
   (-> #:function procedure? #:input-arity natural? #:output-arity natural?
       rpn-operator?)]
  [rpn-operator? predicate/c]
  [rpn-operator-function (-> rpn-operator? procedure?)]
  [rpn-operator-input-arity (-> rpn-operator? natural?)]
  [rpn-operator-output-arity (-> rpn-operator? natural?)]
  [into-rpn reducer?]))

(require racket/math
         racket/stream
         racket/struct
         rebellion/collection/list
         rebellion/streaming/reducer
         rebellion/type/record
         rebellion/type/tuple
         rebellion/type/wrapper)

(module+ test
  (require (submod "..")
           rackunit))

;@------------------------------------------------------------------------------

(define-record-type split-list (reversed-head tail))

(define (list->split-list lst)
  (split-list #:reversed-head empty-list #:tail lst))

(define (split-list-take-next lst)
  (define reversed-head (split-list-reversed-head lst))
  (define tail (split-list-tail lst))
  (split-list #:reversed-head (list-insert reversed-head (list-first tail))
              #:tail (list-rest tail)))

(define (list-split lst n)
  (for/fold ([split (list->split-list lst)])
            ([_ (in-range n)])
    (split-list-take-next split)))

;@------------------------------------------------------------------------------

(define (make-rpn-stack-properties descriptor)
  (define type-name (record-type-name (record-descriptor-type descriptor)))
  (define accessor (record-descriptor-accessor descriptor))
  (define custom-write
    (make-constructor-style-printer
     (λ (_) type-name)
     (λ (this) (reverse (accessor this 0)))))
  (list (cons prop:equal+hash (default-record-equal+hash descriptor))
        (cons prop:custom-write custom-write)))

(define-record-type rpn-stack (backing-list)
  #:property-maker make-rpn-stack-properties)

(define-wrapper-type rpn-operand)
(define-record-type rpn-operator (function input-arity output-arity))

(define (rpn-instruction? v) (or (rpn-operand? v) (rpn-operator? v)))

(define empty-rpn-stack (rpn-stack #:backing-list empty-list))

(define (rpn-stack-push stack instruction)
  (define backing-list (rpn-stack-backing-list stack))
  (cond
    [(rpn-operand? instruction)
     (define value (rpn-operand-value instruction))
     (rpn-stack #:backing-list (list-insert backing-list value))]
    [else
     (define function (rpn-operator-function instruction))
     (define input-arity (rpn-operator-input-arity instruction))
     (define output-arity (rpn-operator-output-arity instruction))
     (define split (list-split backing-list input-arity))
     (define new-backing-list
       (call-with-values (λ ()
                           (apply function (split-list-reversed-head split)))
                         (λ outputs
                           (for/fold ([backing-list (split-list-tail split)])
                                     ([v (in-list outputs)])
                             (list-insert backing-list v)))))
     (rpn-stack #:backing-list new-backing-list)]))


(define into-rpn (make-fold-reducer rpn-stack-push empty-rpn-stack))

(define (rpn . instructions)
  (define (coerce instruction)
    (if (or (rpn-operator? instruction) (rpn-operand? instruction))
        instruction
        (rpn-operand instruction)))
  (apply reduce (reducer-map into-rpn #:domain coerce) instructions))

(define (binary-rpn-operator op)
  (rpn-operator #:function op #:input-arity 2 #:output-arity 1))

(define r+ (binary-rpn-operator +))
(define r- (binary-rpn-operator -))
(define r* (binary-rpn-operator *))
(define r/ (binary-rpn-operator /))

(module+ test
  (test-case "integration-test"
    (check-equal? (rpn 1 2 r+) (rpn 3))
    (check-equal? (rpn 3 4 5 r* r-) (rpn -17))
    (check-equal? (rpn 1 2 3 4 r+ r+) (rpn 1 9))
    (check-equal? (rpn 15 7 1 1 r+ r- r/ 3 r* 2 1 1 r+ r+ r-) (rpn 5))))
