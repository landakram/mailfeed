(include "smtp-mta")

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

#;(main (open-input-string "EHLO bar.com\r\nQUIT\r\n") (current-output-port))
#;(main (open-input-string (string-concatenate rfc-D.1)) (current-output-port))

(process-message-procedure (lambda (peer mailfrom rcptos data)
                             (print "peer:")
                             (print peer)
                             (print "mailfrom:")
                             (print mailfrom)
                             (print "rcptos")
                             (print rcptos)
                             (print "the data:")
                             (print data)))

(smtp-mta (open-input-string (string-concatenate rfc-D.1)) (current-output-port))
