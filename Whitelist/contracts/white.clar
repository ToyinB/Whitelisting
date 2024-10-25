;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-expiration (err u102))
(define-constant err-invalid-address (err u103))
(define-constant minimum-expiration u1440)

;; Define data map for the whitelist
(define-map whitelist
  { addr: principal }
  { expiration: uint,
    active: bool })

;; Private helper functions
(define-private (is-valid-expiration-time (expiration-time uint))
  (>= expiration-time (+ block-height minimum-expiration)))

(define-private (is-valid-address (address principal))
  (not (is-eq address contract-owner)))

(define-private (is-authorized)
  (is-eq tx-sender contract-owner))

;; Read-only functions
(define-read-only (is-whitelisted (address principal))
  (match (map-get? whitelist { addr: address })
    entry (ok (and (get active entry)
                  (>= (get expiration entry) block-height)))
    (ok false)))

;; Public functions
(define-public (add-to-whitelist (address principal) (expiration-time uint))
  (begin
    (asserts! (is-authorized) err-owner-only)
    (asserts! (is-valid-address address) err-invalid-address)
    (asserts! (is-valid-expiration-time expiration-time) err-invalid-expiration)
    (ok (map-set whitelist
        { addr: address }
        { expiration: expiration-time,
          active: true }))))

(define-public (deactivate-whitelist-entry (address principal))
  (begin
    (asserts! (is-authorized) err-owner-only)
    (asserts! (is-valid-address address) err-invalid-address)
    (match (map-get? whitelist { addr: address })
      entry
      (ok (map-set whitelist
        { addr: address }
        { expiration: (get expiration entry),
          active: false }))
      err-not-found)))

(define-public (update-expiration (address principal) (new-expiration uint))
  (begin
    (asserts! (is-authorized) err-owner-only)
    (asserts! (is-valid-address address) err-invalid-address)
    (asserts! (is-valid-expiration-time new-expiration) err-invalid-expiration)
    (match (map-get? whitelist { addr: address })
      entry
      (ok (map-set whitelist
        { addr: address }
        { expiration: new-expiration,
          active: (get active entry) }))
      err-not-found)))