; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Define data variables
(define-data-var whitelist (list 100 { addr: principal, expiration: uint }) (list))

;; Read-only functions
(define-read-only (is-whitelisted (addr principal))
  (match (find-entry addr)
    entry (ok (> (get expiration entry) block-height))
    (ok false)))

(define-read-only (get-whitelist)
  (ok (var-get whitelist)))

;; Private functions
(define-private (find-entry (addr principal))
  (fold check-entry (var-get whitelist) none))

(define-private (check-entry (entry { addr: principal, expiration: uint }) (result (optional { addr: principal, expiration: uint })))
  (match result
    found found
    (if (is-eq (get addr entry) addr)
      (some entry)
      none)))

(define-private (remove-entry (addr principal) (entries (list 100 { addr: principal, expiration: uint })))
  (fold remove-if-match entries (list)))

(define-private (remove-if-match (entry { addr: principal, expiration: uint }) (acc (list 100 { addr: principal, expiration: uint })))
  (if (is-eq (get addr entry) addr)
    acc
    (append acc entry)))

(define-private (update-entry (addr principal) (new-expiration uint) (entries (list 100 { addr: principal, expiration: uint })))
  (fold update-if-match 
        entries 
        (list)
        { target-addr: addr, new-expiration: new-expiration }))

(define-private (update-if-match 
  (entry { addr: principal, expiration: uint }) 
  (acc (list 100 { addr: principal, expiration: uint }))
  (params { target-addr: principal, new-expiration: uint }))
  (let ((target-addr (get target-addr params))
        (new-expiration (get new-expiration params)))
    (if (is-eq (get addr entry) target-addr)
        (append acc { addr: target-addr, expiration: new-expiration })
        (append acc entry))))

;; Public functions
(define-public (add-to-whitelist (addr principal) (expiration uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (find-entry addr)
      entry err-already-exists
      (ok (var-set whitelist (append (var-get whitelist) 
                                     (list { addr: addr, expiration: expiration })))))))

(define-public (remove-from-whitelist (addr principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set whitelist (remove-entry addr (var-get whitelist))))))

(define-public (update-expiration (addr principal) (new-expiration uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (find-entry addr)
      entry (ok (var-set whitelist (update-entry addr new-expiration (var-get whitelist))))
      err-not-found)))