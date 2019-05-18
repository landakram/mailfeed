(include "smtp-server")

;; Test stuff

(import srfi-13)
(define rfc-D.1
  `(
    "EHLO bar.com\r\n"
    "MAIL FROM:<Smith@bar.com>\r\n"
    "RCPT TO:<Jones@foo.com>\r\n"
    "RCPT TO:<Green@foo.com>\r\n"
    "RCPT TO:<Brown@foo.com>\r\n"
    "DATA\r\n"
    "Blah blah blah...\r\n...etc. etc. etc.\r\n"
    ".\r\n"
    "QUIT\r\n"
    ))

;; (smtp-mta (open-input-string "EHLO example.com\r\nQUIT\r\n") (current-output-port))
;; (smtp-mta (open-input-string "EHLO [127.0.0.2]\r\nQUIT\r\n") (current-output-port))
#;(main (open-input-string (string-concatenate rfc-D.1)) (current-output-port))

(define (process-message peer mailfrom rcptos data)
  '())
(define (process-message peer mailfrom rcptos data)
  ((logger) "peer: ~S" peer)
  ((logger) "mailfrom: ~S" mailfrom)
  ((logger) "rcptos: ~S" rcptos)
  ((logger) "data: ~S" data))

(define smtp-server (make-smtp-server 6504 process-message))
(smtp-server #t)
