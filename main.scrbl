#lang scribble/manual

@(require (for-label racket/base
                     racket/contract/base
                     racket/math
                     rebellion/streaming/reducer
                     rpn)
          scribble/example)

@(define make-evaluator
   (make-eval-factory (list 'rpn)))

@title{Reverse Polish Notation}
@defmodule[rpn]

Reverse Polish Notation (RPN) is a way of writing expressions commonly found in
calculators and Forth-like programming languages. In RPN, an expression is a
list of instructions for manipulating data on a @emph{stack}. The most basic
instruction is to push a value onto the stack. Function call instructions pop a
function's arguments off the stack and push its results onto the stack. The
@racketmodname[rpn] library represents an RPN program as a call to the @racket[
 rpn] function with the program instructions as arguments.

@(examples
  #:eval (make-evaluator) #:once
  (rpn 1)
  (rpn 1 2 3)
  (rpn 1 2 3 r*)
  (rpn 1 2 3 r* r+)
  (rpn 1 2 3 r* r+ 2)
  (rpn 1 2 3 r* r+ 2 r-))

@section{RPN Stacks}

@defproc[(rpn-stack? [v any/c]) boolean?]

@defthing[empty-rpn-stack rpn-stack? #:value (rpn)]

@defproc[(rpn-stack-push [stack rpn-stack?]
                         [instruction rpn-instruction?])
         rpn-stack?]

@section{RPN Instructions}

@defproc[(rpn-instruction? [v any/c]) boolean?]

@subsection{Pushing Operands}

@defproc[(rpn-operand? [v any/c]) boolean?]
@defproc[(rpn-operand [v any/c]) rpn-operand?]
@defproc[(rpn-operand-value [operand rpn-operand?]) any/c]

@subsection{Calling Operators}

@defproc[(rpn-operator? [v any/c]) boolean?]

@defproc[(binary-rpn-operator [binary-function (-> any/c any/c any/c)])
         rpn-operator?]

@defproc[(rpn-operator [#:function function procedure?]
                       [#:input-arity input-arity natural?]
                       [#:output-arity output-arity natural?])
         rpn-operator?]

@defproc[(rpn-operator-function [operator rpn-operator?]) procedure?]
@defproc[(rpn-operator-input-arity [operator rpn-operator?]) natural?]
@defproc[(rpn-operator-output-arity [operator rpn-operator?]) natural?]

@subsection{Arithmetic Operators}

@defthing[r+ rpn-operator? #:value (binary-rpn-operator +)]
@defthing[r- rpn-operator? #:value (binary-rpn-operator -)]
@defthing[r* rpn-operator? #:value (binary-rpn-operator *)]
@defthing[r/ rpn-operator? #:value (binary-rpn-operator /)]

@section{RPN Notation}

@defproc[(rpn [instruction any/c] ...) rpn-stack?]

@section{Streaming RPN Computations}

@defthing[into-rpn reducer?]
