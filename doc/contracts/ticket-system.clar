;; ticket-system.clar
;; A decentralized customer support ticketing system

;; Constants and Definitions
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_TICKET_NOT_FOUND (err u101))
(define-constant ERR_INVALID_STATUS (err u102))
(define-constant ERR_INVALID_INPUT (err u103))

;; Define ticket status values
(define-constant STATUS_OPEN u1)
(define-constant STATUS_IN_PROGRESS u2)
(define-constant STATUS_RESOLVED u3)
(define-constant STATUS_CLOSED u4)

;; Data structures
(define-map tickets
  { ticket-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    status: uint,
    created-at: uint,
    updated-at: uint
  }
)

(define-map ticket-comments
  { ticket-id: uint, comment-id: uint }
  {
    author: principal,
    content: (string-utf8 500),
    created-at: uint
  }
)

(define-map support-staff
  { address: principal }
  { is-active: bool }
)

;; Data variables
(define-data-var ticket-id-counter uint u0)
(define-data-var comment-id-counter uint u0)

;; Private functions
(define-private (is-staff (address principal))
  (default-to false (get is-active (map-get? support-staff { address: address })))  
)

(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (is-ticket-owner (ticket-id uint))
  (let ((ticket-data (map-get? tickets { ticket-id: ticket-id })))
    (if (is-some ticket-data)
      (is-eq tx-sender (get owner (unwrap-panic ticket-data)))
      false
    )
  )
)

(define-private (authorized-for-ticket (ticket-id uint))
  (or (is-contract-owner) (is-staff tx-sender) (is-ticket-owner ticket-id))
)

(define-private (is-valid-status (status uint))
  (and 
    (>= status STATUS_OPEN)
    (<= status STATUS_CLOSED)
  )
)

;; Public functions
(define-public (create-ticket (title (string-utf8 100)) (description (string-utf8 500)))
  (begin
    ;; Input validation
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    (asserts! (> (len description) u0) ERR_INVALID_INPUT)
    
    (let
      (
        (new-id (+ (var-get ticket-id-counter) u1))
      )
      (var-set ticket-id-counter new-id)
      (map-set tickets
        { ticket-id: new-id }
        {
          owner: tx-sender,
          title: title,
          description: description,
          status: STATUS_OPEN,
          created-at: block-height,
          updated-at: block-height
        }
      )
      (ok new-id)
    )
  )
)

(define-public (update-ticket-status (ticket-id uint) (new-status uint))
  (let
    (
      (ticket-data (map-get? tickets { ticket-id: ticket-id }))
    )
    (asserts! (is-some ticket-data) ERR_TICKET_NOT_FOUND)
    ;; BUG FIX: Use authorized-for-ticket instead of direct staff check
    (asserts! (authorized-for-ticket ticket-id) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    
    (map-set tickets
      { ticket-id: ticket-id }
      (merge (unwrap-panic ticket-data)
        {
          status: new-status,
          updated-at: block-height
        }
      )
    )
    (ok true)
  )
)

(define-public (add-comment (ticket-id uint) (content (string-utf8 500)))
  (begin
    ;; Input validation
    (asserts! (> (len content) u0) ERR_INVALID_INPUT)
    
    (let
      (
        (ticket-data (map-get? tickets { ticket-id: ticket-id }))
        (new-comment-id (+ (var-get comment-id-counter) u1))
      )
      (asserts! (is-some ticket-data) ERR_TICKET_NOT_FOUND)
      (asserts! (authorized-for-ticket ticket-id) ERR_NOT_AUTHORIZED)
      
      (var-set comment-id-counter new-comment-id)
      (map-set ticket-comments
        { ticket-id: ticket-id, comment-id: new-comment-id }
        {
          author: tx-sender,
          content: content,
          created-at: block-height
        }
      )
      (ok new-comment-id)
    )
  )
)

;; Read-only functions
(define-read-only (get-ticket (ticket-id uint))
  (map-get? tickets { ticket-id: ticket-id })
)

(define-read-only (get-ticket-comment (ticket-id uint) (comment-id uint))
  (map-get? ticket-comments { ticket-id: ticket-id, comment-id: comment-id })
)

(define-read-only (get-tickets-by-owner (owner principal))
  (filter get-ticket-by-id (map-to-ids (var-get ticket-id-counter)))
)

(define-private (map-to-ids (max-id uint))
  (map add-one (list max-id))
)

(define-private (add-one (id uint))
  (+ id u1)
)

(define-private (get-ticket-by-id (id uint))
  (let ((ticket-data (map-get? tickets { ticket-id: id })))
    (and (is-some ticket-data) (is-eq (get owner (unwrap-panic ticket-data)) tx-sender))
  )
)

;; Staff management functions
(define-public (add-staff-member (address principal))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set support-staff { address: address } { is-active: true })
    (ok true)
  )
)

(define-public (remove-staff-member (address principal))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (map-set support-staff { address: address } { is-active: false })
    (ok true)
  )
)

;; Check if a user is authorized to manage a ticket
(define-read-only (can-manage-ticket (ticket-id uint) (user principal))
  (let ((ticket-data (map-get? tickets { ticket-id: ticket-id })))
    (if (is-some ticket-data)
      (or 
        (is-eq user CONTRACT_OWNER) 
        (is-staff user) 
        (is-eq user (get owner (unwrap-panic ticket-data)))
      )
      false
    )
  )
)
