#lang racket

(require benchmark   ;; for specifying our benchmarks
         plot        ;; for plotting results
         racket/set  ;; racket set implementation
         )

;; specifying the sets we will query

(define list-sizes (list 10 20 30 40))

(define unfiltered-samples
  (for/list ([i list-sizes]) (for/list ([j i]) j)))

;; our sample lists contain the even values of unfiltered-samples
(define sample-lists
  (map (lambda (l) (filter even? l)) unfiltered-samples))

;; make sets from sample-lists
(define sample-sets
  (for/list ([l sample-lists]) (list->set l)))

(define sample-vals unfiltered-samples)

;; benchmark lookup-fn querying set for each of vals
(define (mk-bench lookup-fn set vals set-count)
  (b1
   ;; name of this benchmark
   (format "~a/~a" set-count (length vals))
   ;; expression to benchmark
   (map (lambda (v) (lookup-fn set v)) vals)))

(define benches
  (list
   (bgroup
    "list set" ;; name of this group
    ;; list of benchmark-one? in this group (one per element of sample-lists)
    (map (lambda (set vals)
           (mk-bench (lambda (lst v) (member v lst)) set vals (length set)))
         sample-lists
         sample-vals))
   (bgroup
    "racket set" ;; name of this group
    ;; list of benchmark-one? in this group (one per element of sample-sets)
    (map (lambda (set vals)
           (mk-bench set-member? set vals (set-count set)))
         sample-sets
         sample-vals))))

(define results
  (run-benchmarks
   benches                      ;; benchmarks to run
   (bopts
    ;; don't run gc between each iteration (because it takes a long time
    ;; to build the document when gc runs)
    #:gc-between #f
    ;; number of iterations to time. i.e. time how long 100 iterations
    #:itrs-per-trial 100
    ;; number of trials to run. i.e. we make 50 measurements of rounds of
    ;; running 100 benchmraks
    #:num-trials 50)))

;; plot the results
(parameterize ([plot-x-ticks no-ticks])
  (plot-pict
   #:title "sets"
   #:y-label "normalized time"
   #:x-label "list size/num queries"
   (render-benchmark-alts
    ;; list of alternatives to compare. here we want to compare the
    ;; racket set and list set groups.
    (list "racket set" "list set")
    results                        ;; benchmark results
    "racket set"                   ;; alternative to use as our baseline
    )))