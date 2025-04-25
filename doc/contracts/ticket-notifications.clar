;; ticket-notifications.clar
;; Handles ticket notifications and subscription system

;; Constants and definitions
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))

;; Data structures
(define-map user-subscriptions
  { user: principal }
  { categories: (list 20 uint) }
)

(define-map notifications
  { notification-id: uint }
  {
    ticket-id: uint,
    message: (string-utf8 200),
    created-at: uint,
    read: bool
  }
)

(define-map user-notifications
  { user: principal, notification-id: uint }
  { read: bool }
)

;; Variables
(define-data-var notification-id-counter uint u0)

;; Subscription management
(define-public (subscribe-to-categories (categories (list 20 uint)))
  (begin
    (map-set user-subscriptions
      { user: tx-sender }
      { categories: categories }
    )
    (ok true)
  )
)

(define-public (unsubscribe-from-all)
  (begin
    (map-delete user-subscriptions { user: tx-sender })
    (ok true)
  )
)

;; Notification functions
(define-public (create-notification (ticket-id uint) (message (string-utf8 200)) (category-id uint))
  (let ((auth-check (contract-call? .ticket-system can-manage-ticket ticket-id tx-sender)))
    (asserts! auth-check ERR_NOT_AUTHORIZED)
    
    ;; Now after authorization check is done
    (let ((new-id (+ (var-get notification-id-counter) u1)))
      (var-set notification-id-counter new-id)
      
      ;; Create the notification
      (map-set notifications
        { notification-id: new-id }
        {
          ticket-id: ticket-id,
          message: message,
          created-at: block-height,
          read: false
        }
      )
      
      ;; Call notification function - simplified approach
      (notify-subscribed-users new-id category-id)
      (ok new-id)
    )
  )
)

(define-private (notify-subscribed-users (notification-id uint) (category-id uint))
  ;; This is a simplified version since Clarity doesn't support iterating over maps
  ;; In a production environment, you would implement this differently
  ;; For this example, we're just illustrating the concept
  (begin
    ;; In a real implementation, you would notify users here
    true
  )
)

(define-public (mark-notification-as-read (notification-id uint))
  (begin
    (asserts! (is-some (map-get? notifications { notification-id: notification-id })) ERR_NOT_FOUND)
    
    (map-set user-notifications
      { user: tx-sender, notification-id: notification-id }
      { read: true }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-user-subscriptions (user principal))
  (map-get? user-subscriptions { user: user })
)

(define-read-only (get-notification (notification-id uint))
  (map-get? notifications { notification-id: notification-id })
)

(define-read-only (is-notification-read (user principal) (notification-id uint))
  (default-to 
    false 
    (get read (map-get? user-notifications { user: user, notification-id: notification-id }))
  )
)
