;; stackwork.clar
;; A decentralized job marketplace smart contract for Stacks (STX)
;; Allows posting jobs, applying, escrow payments, and rating users.

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_EMPLOYER u100)
(define-constant ERR_NOT_FREELANCER u101)
(define-constant ERR_ALREADY_APPLIED u102)
(define-constant ERR_NOT_HIRED u103)
(define-constant ERR_INVALID_AMOUNT u104)
(define-constant ERR_ALREADY_SUBMITTED u105)
(define-constant ERR_NOT_FOUND u106)
(define-constant ERR_ALREADY_APPROVED u107)
(define-constant ERR_ALREADY_RATED u108)

;; --------------------------------
;; DATA STORAGE
;; --------------------------------
(define-data-var next-job-id uint u0)

(define-map jobs
  uint
  (tuple
    (employer principal)
    (title (string-ascii 64))
    (description (string-ascii 256))
    (budget uint)
    (deadline uint)
    (status (string-ascii 32)) ;; open / hired / submitted / complete / canceled
    (hired (optional principal))
    (submission (optional (string-ascii 256)))
  )
)

(define-map applications
  (tuple (job-id uint) (freelancer principal))
  bool
)

(define-map ratings
  principal
  (tuple (count uint) (total uint))
)

;; --------------------------------
;; EVENTS (Note: Clarity doesn't have event system like Solidity)
;; --------------------------------
;; Events are simulated through contract calls and logs

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; 1. Create a job (escrow funds)
(define-public (create-job (title (string-ascii 64)) (description (string-ascii 256)) (budget uint) (duration uint))
  (if (> budget u0)
      (let ((id (+ (var-get next-job-id) u1)))
        (try! (stx-transfer? budget tx-sender contract-caller))
        (map-set jobs id
          (tuple
            (employer tx-sender)
            (title title)
            (description description)
            (budget budget)
            (deadline (+ burn-block-height duration))
            (status "open")
            (hired none)
            (submission none)
          ))
        (var-set next-job-id id)
        (ok (tuple (job-id id) (budget budget))))
      (err ERR_INVALID_AMOUNT))
)

;; 2. Apply to a job
(define-public (apply-job (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job
      j
        (if (is-eq (get status j) "open")
            (let ((existing-app (map-get? applications (tuple (job-id job-id) (freelancer tx-sender)))))
              (match existing-app
                app (err ERR_ALREADY_APPLIED)
                (begin
                  (map-set applications (tuple (job-id job-id) (freelancer tx-sender)) true)
                  (ok "Application submitted"))))
            (err ERR_NOT_FOUND))
      (err ERR_NOT_FOUND)))
)

;; 3. Hire a freelancer
(define-public (hire (job-id uint) (freelancer principal))
  (let ((job (map-get? jobs job-id)))
    (match job
      j
        (if (and (is-eq tx-sender (get employer j)) (is-eq (get status j) "open"))
            (begin
              (map-set jobs job-id
                (tuple
                  (employer (get employer j))
                  (title (get title j))
                  (description (get description j))
                  (budget (get budget j))
                  (deadline (get deadline j))
                  (status "hired")
                  (hired (some freelancer))
                  (submission none)))
              (ok "Freelancer hired"))
            (err ERR_NOT_EMPLOYER))
      (err ERR_NOT_FOUND)))
)

;; 4. Submit work
(define-public (submit-work (job-id uint) (work-link (string-ascii 256)))
  (let ((job (map-get? jobs job-id)))
    (match job
      j
        (if (and (is-some (get hired j))
                 (is-eq (unwrap-panic (get hired j)) tx-sender))
            (if (is-eq (get status j) "hired")
                (begin
                  (map-set jobs job-id
                    (tuple
                      (employer (get employer j))
                      (title (get title j))
                      (description (get description j))
                      (budget (get budget j))
                      (deadline (get deadline j))
                      (status "submitted")
                      (hired (get hired j))
                      (submission (some work-link))))
                  (ok "Work submitted"))
                (err ERR_ALREADY_SUBMITTED))
            (err ERR_NOT_FREELANCER))
      (err ERR_NOT_FOUND)))
)

;; 5. Approve and release funds
(define-public (approve-work (job-id uint))
  (let ((job (map-get? jobs job-id)))
    (match job
      j
        (if (and (is-eq tx-sender (get employer j))
                 (is-eq (get status j) "submitted"))
            (let ((freelancer (unwrap-panic (get hired j))))
              (try! (stx-transfer? (get budget j) contract-caller freelancer))
              (map-set jobs job-id
                (tuple
                  (employer (get employer j))
                  (title (get title j))
                  (description (get description j))
                  (budget (get budget j))
                  (deadline (get deadline j))
                  (status "complete")
                  (hired (get hired j))
                  (submission (get submission j))))
              (ok "Payment released"))
            (err ERR_NOT_EMPLOYER))
      (err ERR_NOT_FOUND)))
)

;; 6. Rate a user (1-5 stars)
(define-public (rate-user (user principal) (score uint))
  (if (and (>= score u1) (<= score u5))
      (let ((r (map-get? ratings user)))
        (match r
          rr
            (begin
              (map-set ratings user
                (tuple
                  (count (+ (get count rr) u1))
                  (total (+ (get total rr) score))))
              (ok "User rated"))
          (begin
            (map-set ratings user (tuple (count u1) (total score)))
            (ok "First rating recorded"))))
      (err ERR_INVALID_AMOUNT))
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------

(define-read-only (get-job (id uint))
  (map-get? jobs id)
)

(define-read-only (get-rating (user principal))
  (let ((r (map-get? ratings user)))
    (match r
      rr (/ (get total rr) (get count rr))
      u0))
)

(define-read-only (get-status (id uint))
  (let ((j (map-get? jobs id)))
    (match j
      jj (get status jj)
      "not-found"))
)
