;; Institution Verification Contract
;; Validates quantum finance systems and institutions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSTITUTION_EXISTS (err u101))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Institution status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    quantum-capability-level: uint,
    verification-date: uint,
    status: uint,
    risk-rating: uint
  }
)

(define-map institution-principals
  { principal: principal }
  { institution-id: uint }
)

(define-data-var next-institution-id uint u1)

;; Register a new institution
(define-public (register-institution (name (string-ascii 100)) (quantum-level uint) (risk-rating uint))
  (let ((institution-id (var-get next-institution-id)))
    (asserts! (is-none (map-get? institution-principals { principal: tx-sender })) ERR_INSTITUTION_EXISTS)
    (asserts! (<= quantum-level u10) ERR_INVALID_STATUS)
    (asserts! (<= risk-rating u10) ERR_INVALID_STATUS)

    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        quantum-capability-level: quantum-level,
        verification-date: block-height,
        status: STATUS_PENDING,
        risk-rating: risk-rating
      }
    )

    (map-set institution-principals
      { principal: tx-sender }
      { institution-id: institution-id }
    )

    (var-set next-institution-id (+ institution-id u1))
    (ok institution-id)
  )
)

;; Verify an institution (admin only)
(define-public (verify-institution (institution-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? institutions { institution-id: institution-id })) ERR_INSTITUTION_NOT_FOUND)

    (map-set institutions
      { institution-id: institution-id }
      (merge (unwrap-panic (map-get? institutions { institution-id: institution-id }))
             { status: STATUS_VERIFIED, verification-date: block-height })
    )
    (ok true)
  )
)

;; Get institution details
(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

;; Check if institution is verified
(define-read-only (is-institution-verified (institution-id uint))
  (match (map-get? institutions { institution-id: institution-id })
    institution (is-eq (get status institution) STATUS_VERIFIED)
    false
  )
)

;; Get institution by principal
(define-read-only (get-institution-by-principal (principal principal))
  (match (map-get? institution-principals { principal: principal })
    mapping (map-get? institutions { institution-id: (get institution-id mapping) })
    none
  )
)
