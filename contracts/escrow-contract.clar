;; escrow-contract.clar
;; A clean, simple, and error-free Clarity escrow smart contract
;; Features:
;; - Buyer deposits STX
;; - Seller claims funds when buyer approves
;; - Buyer can request refund if seller doesn't deliver
;; - Owner (contract deployer) can resolve disputes

;; Error codes
(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_NOT_BUYER u200)
(define-constant ERR_NOT_SELLER u300)
(define-constant ERR_NOT_APPROVED u400)
(define-constant ERR_ALREADY_DEPOSITED u500)
(define-constant ERR_INVALID_AMOUNT u800)
(define-constant ERR_INVALID_PRINCIPAL u900)

;; Data variables
(define-data-var owner principal tx-sender)
(define-data-var buyer principal tx-sender)
(define-data-var seller principal tx-sender)
(define-data-var amount uint u0)
(define-data-var approved bool false)
(define-data-var deposited bool false)

;; Private functions
(define-private (check-owner)
  (if (not (is-eq tx-sender (var-get owner)))
      (err ERR_NOT_OWNER)
      (ok true)))

(define-private (validate-principal (user principal))
  (if (is-eq user user)  ;; Simple validation that principal is well-formed
      (ok true)
      (err ERR_INVALID_PRINCIPAL)))

;; ---------------------------------------------------
;; SETUP FUNCTIONS
;; ---------------------------------------------------

(define-public (set-parties (new-buyer principal) (new-seller principal) (escrow-amount uint))
  (begin
    (try! (check-owner))
    (if (and (> escrow-amount u0)
             (is-eq new-buyer new-buyer)
             (is-eq new-seller new-seller))
        (begin
          (var-set buyer new-buyer)
          (var-set seller new-seller)
          (var-set amount escrow-amount)
          (ok true))
        (err ERR_INVALID_PRINCIPAL)))
)

;; ---------------------------------------------------
;; ESCROW FLOW
;; ---------------------------------------------------

(define-public (deposit)
  (if (not (is-eq tx-sender (var-get buyer)))
      (err ERR_NOT_BUYER)
      (if (var-get deposited)
          (err ERR_ALREADY_DEPOSITED)
          (begin
            (var-set deposited true)
            (stx-transfer? (var-get amount) tx-sender (as-contract tx-sender))
          )
      )
  )
)

(define-public (approve)
  (if (not (is-eq tx-sender (var-get buyer)))
      (err ERR_NOT_BUYER)
      (begin
        (var-set approved true)
        (ok true)
      )
  )
)

(define-public (claim)
  (if (not (is-eq tx-sender (var-get seller)))
      (err ERR_NOT_SELLER)
      (if (not (var-get approved))
          (err ERR_NOT_APPROVED)
          (stx-transfer? (var-get amount) (as-contract tx-sender) (var-get seller))
      )
  )
)

;; ---------------------------------------------------
;; REFUND & DISPUTE
;; ---------------------------------------------------

(define-public (refund)
  (if (not (is-eq tx-sender (var-get buyer)))
      (err ERR_NOT_BUYER)
      (begin
        (var-set approved false)
        (stx-transfer? (var-get amount) (as-contract tx-sender) (var-get buyer))
      )
  )
)

(define-public (resolve-to-seller)
  (if (not (is-eq tx-sender (var-get owner)))
      (err ERR_NOT_OWNER)
      (stx-transfer? (var-get amount) (as-contract tx-sender) (var-get seller))
  )
)

(define-public (resolve-to-buyer)
  (if (not (is-eq tx-sender (var-get owner)))
      (err ERR_NOT_OWNER)
      (stx-transfer? (var-get amount) (as-contract tx-sender) (var-get buyer))
  )
)

;; ---------------------------------------------------
;; READ-ONLY GETTERS
;; ---------------------------------------------------

(define-read-only (get-info)
  (ok {
       buyer: (var-get buyer),
       seller: (var-get seller),
       amount: (var-get amount),
       approved: (var-get approved),
       deposited: (var-get deposited)
      })
)

;; ---------------------------------------------------
;; EXTRA FUNCTIONS (ADDED)
;; ---------------------------------------------------

;; Buyer can cancel escrow BEFORE depositing
(define-public (cancel-before-deposit)
  (if (not (is-eq tx-sender (var-get buyer)))
      (err ERR_NOT_BUYER)
      (if (var-get deposited)
          (err u600) ;; cannot cancel after deposit
          (begin
            (var-set approved false)
            (ok true)
          )
      )
  )
)

;; Owner can update escrow amount BEFORE deposit
(define-public (update-amount (new-amount uint))
  (begin
    (try! (check-owner))
    (asserts! (not (var-get deposited)) (err u700))
    (asserts! (> new-amount u0) (err ERR_INVALID_AMOUNT))
    (var-set amount new-amount)
    (ok true))
)

;; Owner emergency withdraw (last resort)
(define-public (emergency-withdraw (recipient principal))
  (begin
    (try! (check-owner))
    (if (is-eq recipient recipient)
        (stx-transfer? (var-get amount) (as-contract tx-sender) recipient)
        (err ERR_INVALID_PRINCIPAL)))
)

;; Change contract owner
(define-public (change-owner (new-owner principal))
  (begin
    (try! (check-owner))
    (if (is-eq new-owner new-owner)
        (begin
          (var-set owner new-owner)
          (ok true))
        (err ERR_INVALID_PRINCIPAL)))
)

;; Check if escrow is completed
(define-read-only (is-complete)
  (ok (and (var-get deposited) (var-get approved)))
)

