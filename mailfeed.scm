
(import datatype smtp abnf srfi-1 (chicken format) symbol-utils)


(define domain    "example.net")
(define host      "chicken-mta")
(define mailfrom  (make-parameter #f))
(define rcpto     (make-parameter '()))
(define data      (make-parameter #f))
(define process-message (make-parameter
                         (lambda (peer mailfrom rcptos data) '())))

(define (handle-event ev)
  (cases event ev
         (SayHelo (s)
                  (Reply (Code (Success) (MailSystem) 0)
                         (list host " " "Hello " s)))
         
         (SayHeloAgain (s)
                       (Reply (Code (Success) (MailSystem) 0)
                              (list host " " "Hello " s)))

         (SayEhlo (s)
                  (Reply (Code (Success) (MailSystem) 0)
                         (list host " " "Hello " s)))
         
         (SayEhloAgain (s)
                       (Reply (Code (Success) (MailSystem) 0)
                              (list host " " "Hello " s)))
         
         (SetMailFrom (m)
                      (mailfrom m)
                      (Reply (Code (Success) (MailSystem) 0) 
                             (list "OK")))

         (AddRcptTo (m)
                    (if (not (mailfrom))
                        (Reply (Code (PermanentFailure) (Syntax) 3)
                               (list "command out of sequence"))
                        (begin
                          (rcpto (cons m (rcpto)))
                          (Reply (Code (Success) (MailSystem) 0) 
                                 (list "Accepted")))))

         (StartData ()
                    (if (not (rcpto))
                        (Reply (Code (PermanentFailure) (MailSystem) 4)
                               (list "no valid recipients"))
                        (begin
                          (data (list))
                          (Reply (Code (IntermediateSuccess) (MailSystem) 4)
                                 (list "Ready")))))

         (NeedHeloFirst ()
                        (Reply (Code (PermanentFailure) (Syntax) 3)
                               (list "command out of sequence: "
                                     "need HELO first")
                               ))

         (NeedMailFromFirst ()
                            (Reply (Code (PermanentFailure) (Syntax) 3)
                                   (list "command out of sequence: "
                                         "need MAIL first")
                                   ))

         (NeedMailRcptToFirst ()
                              (Reply (Code (PermanentFailure) (Syntax) 3)
                                     (list "command out of sequence: "
                                           "need RCPT first")
                                     ))

         (NotImplemented ()
                         (Reply (Code (PermanentFailure) (Syntax) 2)
                                (list "command not implemented")))


         (ResetState ()
                     (mailfrom #f)
                     (rcpto    #f)
                     (data     #f)
                     (Reply (Code (Success) (MailSystem) 0) 
                            (list "Reset OK")))

         (SayOK ()
                (Reply (Code (Success) (MailSystem) 0) 
                       (list "OK")))

         (SeeksHelp (s)
                    (Reply (Code (Success) (Information) 4) 
                           (list "Commands supported:"
                                 "HELO EHLO MAIL RCPT DATA QUIT RSET NOOP HELP")))

         (Shutdown ()
                   (Reply (Code (Success) (MailSystem) 1)
                          (list host " closing connection")))

         (SyntaxErrorIn (s)
                        (Reply (Code (PermanentFailure) (Syntax) 1)
                               (list "syntax error in " s)))

         (Unrecognized (s)
                       (Reply (Code (PermanentFailure) (Syntax) 0)
                              (list "Unrecognized " s)))
         ))

;; from SSAX lib
(define (peek-next-char port)
  (read-char port) 
  (peek-char port))

(define (read-smtp-line port)
  (let loop ((cs (list)))
    (let ((c (peek-char port)))
      (if (eof-object? c) (reverse cs)
          (let ((n (peek-next-char port)))
            (cond ((and (eq? n #\newline) (eq? c #\return))
                   (begin
                     (read-char port)
                     (reverse (cons* n c cs)))
                   )
                  (else (loop (cons c cs)))))))))

(define data-end (list #\. #\return #\newline))

(define (handle-data in out cont)
  (let loop ((tempdata (list)))
    (let ((line (read-smtp-line in)))
      (if (equal? line data-end)
	  (begin (data (reverse tempdata))
                 (let* ((message-handler (process-message))
                        (maybe-reply (message-handler '() (mailfrom) (rcpto) (data)))
                        (reply (if (or (null? maybe-reply) (unspecified? maybe-reply))
                                   (Reply (Code (Success) (MailSystem) 0) (list "OK"))
                                   maybe-reply)))
                   (fprintf out "~A" reply)
		   (cont))) 
	  (loop (cons (list->string line) tempdata))))))

(define (mta in out)  
  (let loop ((fsm (start-session)))
    (let ((line     (read-smtp-line in)))
      (if (null? line) (loop fsm)
	  (let ((instream `(() ,line)))
	    (let-values
	     (((reply ev fsm)
	       (cases session-fsm (fsm instream)
                      (Event (ev)
                             (let ((reply (handle-event ev)))
			       (values reply ev fsm)))
		      (Trans (ev fsm)
			     (let ((reply (handle-event ev)))
			       (values reply ev fsm))))))
	     (fprintf out "~A" reply)
	     (cases event ev
		    (StartData ()
			       (handle-data in out (lambda () (loop fsm))))
		    (Shutdown ()
			      (begin
                                ))
		    (else (loop fsm)))))))))
		     

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

(process-message (lambda (peer mailfrom rcptos data)
                   (print "peer:")
                   (print peer)
                   (print "mailfrom:")
                   (print mailfrom)
                   (print "rcptos")
                   (print rcptos)
                   (print "the data:")
                   (print data)))

(main (open-input-string (string-concatenate rfc-D.1)) (current-output-port))
