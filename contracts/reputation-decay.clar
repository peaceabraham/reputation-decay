;; title: reputation-decay
;; version: 1.0.0
;; summary: Governance reputation with automatic time-based decay
;; description: Prevents perpetual elites by decaying reputation over time

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-no-reputation (err u102))
(define-constant err-invalid-decay-rate (err u103))

;; Decay rate: percentage of reputation lost per block (in basis points, 100 = 1%)
(define-constant default-decay-rate u50) ;; 0.5% per 100 blocks

;; data vars
(define-data-var decay-rate uint default-decay-rate)
(define-data-var decay-interval uint u100) ;; Decay applied every 100 blocks

;; data maps
;; Track reputation and last update block for each principal
(define-map reputation-ledger
  principal
  {
    reputation: uint,
    last-update-block: uint
  }
)

;; Track total reputation in the system
(define-data-var total-reputation uint u0)

;; private functions

;; Calculate decayed reputation based on blocks elapsed
(define-private (calculate-decay (current-reputation uint) (blocks-elapsed uint))
  (let
    (
      (decay-periods (/ blocks-elapsed (var-get decay-interval)))
      (rate (var-get decay-rate))
    )
    (if (is-eq decay-periods u0)
      current-reputation
      ;; Apply decay: reputation * (1 - rate/10000)^periods
      ;; Simplified: reduce by (rate/10000) per period
      (let
        (
          (total-decay-percent (/ (* decay-periods rate) u10000))
          (decay-amount (/ (* current-reputation total-decay-percent) u100))
        )
        (if (>= decay-amount current-reputation)
          u0
          (- current-reputation decay-amount))
      )
    )
  )
)

;; Update reputation with decay applied
(define-private (apply-decay (user principal))
  (match (map-get? reputation-ledger user)
    entry
      (let
        (
          (blocks-elapsed (- block-height (get last-update-block entry)))
          (decayed-rep (calculate-decay (get reputation entry) blocks-elapsed))
        )
        (map-set reputation-ledger user {
          reputation: decayed-rep,
          last-update-block: block-height
        })
        (ok decayed-rep)
      )
    (ok u0)
  )
)

;; public functions

;; Earn reputation through contributions
(define-public (earn-reputation (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    ;; Apply decay first
    (unwrap! (apply-decay tx-sender) err-invalid-amount)
    ;; Add new reputation
    (match (map-get? reputation-ledger tx-sender)
      entry
        (let
          (
            (new-reputation (+ (get reputation entry) amount))
          )
          (map-set reputation-ledger tx-sender {
            reputation: new-reputation,
            last-update-block: block-height
          })
          (var-set total-reputation (+ (var-get total-reputation) amount))
          (ok new-reputation)
        )
      ;; First time earning reputation
      (begin
        (map-set reputation-ledger tx-sender {
          reputation: amount,
          last-update-block: block-height
        })
        (var-set total-reputation (+ (var-get total-reputation) amount))
        (ok amount)
      )
    )
  )
)

;; Manually trigger decay update for a user
(define-public (update-reputation (user principal))
  (apply-decay user)
)

;; Admin function to set decay rate (in basis points)
(define-public (set-decay-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u10000) err-invalid-decay-rate) ;; Max 100%
    (var-set decay-rate new-rate)
    (ok true)
  )
)

;; Admin function to set decay interval (in blocks)
(define-public (set-decay-interval (new-interval uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-interval u0) err-invalid-amount)
    (var-set decay-interval new-interval)
    (ok true)
  )
)

;; read only functions

;; Get current reputation (with decay applied)
(define-read-only (get-reputation (user principal))
  (match (map-get? reputation-ledger user)
    entry
      (let
        (
          (blocks-elapsed (- block-height (get last-update-block entry)))
          (decayed-rep (calculate-decay (get reputation entry) blocks-elapsed))
        )
        (ok decayed-rep)
      )
    err-no-reputation
  )
)

;; Get raw reputation data (without calculating current decay)
(define-read-only (get-reputation-data (user principal))
  (ok (map-get? reputation-ledger user))
)

;; Get total reputation in system
(define-read-only (get-total-reputation)
  (ok (var-get total-reputation))
)

;; Get current decay rate
(define-read-only (get-decay-rate)
  (ok (var-get decay-rate))
)

;; Get current decay interval
(define-read-only (get-decay-interval)
  (ok (var-get decay-interval))
)

;; Check if user has governance power (reputation above threshold)
(define-read-only (has-governance-power (user principal) (threshold uint))
  (match (get-reputation user)
    current-rep (ok (>= current-rep threshold))
    error (ok false)
  )
)
