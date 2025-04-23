;; ticket-metadata.clar
;; Handles ticket categories, priorities, and SLAs

;; Constants and definitions
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_INPUT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))

;; Define ticket priority levels
(define-constant PRIORITY_LOW u1)
(define-constant PRIORITY_MEDIUM u2)
(define-constant PRIORITY_HIGH u3)
(define-constant PRIORITY_CRITICAL u4)

;; Data structures
(define-map categories
  { category-id: uint }
  {
    name: (string-utf8 50),
    description: (string-utf8 200),
    sla-hours: uint
  }
)

(define-map ticket-metadata
  { ticket-id: uint }
  {
    category-id: uint,
    priority: uint,
    deadline: (optional uint)
  }
)

;; Variables
(define-data-var category-id-counter uint u0)

;; Admin-only functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

;; Category management
(define-public (create-category (name (string-utf8 50)) (description (string-utf8 200)) (sla-hours uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    
    (let ((new-id (+ (var-get category-id-counter) u1)))
      (var-set category-id-counter new-id)
      (map-set categories
        { category-id: new-id }
        {
          name: name,
          description: description,
          sla-hours: sla-hours
        }
      )
      (ok new-id)
    )
  )
)

(define-public (update-category (category-id uint) (name (string-utf8 50)) (description (string-utf8 200)) (sla-hours uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (map-get? categories { category-id: category-id })) ERR_NOT_FOUND)
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    
    (map-set categories
      { category-id: category-id }
      {
        name: name,
        description: description,
        sla-hours: sla-hours
      }
    )
    (ok true)
  )
)

;; Ticket metadata management
(define-public (set-ticket-metadata (ticket-id uint) (category-id uint) (priority uint))
  (let ((auth-check (contract-call? .ticket-system can-manage-ticket ticket-id tx-sender)))
    (asserts! auth-check ERR_NOT_AUTHORIZED)
    (asserts! (and (>= priority PRIORITY_LOW) (<= priority PRIORITY_CRITICAL)) ERR_INVALID_INPUT)
    (asserts! (is-some (map-get? categories { category-id: category-id })) ERR_NOT_FOUND)
    
    (let ((category (unwrap-panic (map-get? categories { category-id: category-id }))))
      (map-set ticket-metadata
        { ticket-id: ticket-id }
        {
          category-id: category-id,
          priority: priority,
          ;; Calculate deadline based on priority and SLA
          deadline: (some (+ block-height 
                            (* (get sla-hours category) u144))) ;; ~6 blocks per hour on Stacks
        }
      )
      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (get-category (category-id uint))
  (map-get? categories { category-id: category-id })
)

(define-read-only (get-ticket-metadata (ticket-id uint))
  (map-get? ticket-metadata { ticket-id: ticket-id })
)

(define-read-only (get-priority-name (priority-level uint))
  (if (is-eq priority-level PRIORITY_LOW)
    "Low"
    (if (is-eq priority-level PRIORITY_MEDIUM)
      "Medium"
      (if (is-eq priority-level PRIORITY_HIGH)
        "High"
        (if (is-eq priority-level PRIORITY_CRITICAL)
          "Critical"
          "Unknown"
        )
      )
    )
  )
)

(define-read-only (is-ticket-overdue (ticket-id uint))
  (let ((metadata (map-get? ticket-metadata { ticket-id: ticket-id })))
    (if (is-some metadata)
      (let ((deadline-opt (get deadline (unwrap-panic metadata))))
        (if (is-some deadline-opt)
          (> block-height (unwrap-panic deadline-opt))
          false
        )
      )
      false
    )
  )
)
