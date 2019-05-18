(import (chicken tcp)
        tcp-server)

(include "smtp-mta")

(define logger (make-parameter #f))

(define (make-smtp-server port process-message-fn)
  (let ((verbose #f)
        (default-name "smtp-server"))

    (define (dribble fstr . args)
      (when verbose
        (fprintf (current-error-port)
                 "[~A] ~?~%~!"
                 (if (string? verbose) verbose default-name)
                 fstr args)))

    (define connect-message
      (Reply (Code (Success) (Connection) 0)
             (list "OK")))

    (logger dribble)
    (process-message-procedure process-message-fn)

    (lambda dbg
      (let ((name (if (equal? dbg '(#t))
                      default-name
                      (optional dbg #f))))
        (set! verbose name)
        ((make-tcp-server
          (tcp-listen port)
          ;; TODO: This needs some error handling, as right now it just fails
          ;; without ever cleaning up the thread.
          (lambda ()
            (fprintf (current-output-port) "~A" connect-message)
            (smtp-mta (current-input-port) (current-output-port))))
         name)))))
