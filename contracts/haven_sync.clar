;; HavenSync - Remote Team Schedule Management Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-team (err u101))
(define-constant err-invalid-slot (err u102))
(define-constant err-slot-taken (err u103))

;; Data Variables
(define-map teams 
    { team-id: uint }
    { name: (string-ascii 64), 
      owner: principal,
      members: (list 50 principal) }
)

(define-map availability
    { user: principal }
    { windows: (list 10 {
        start-time: uint,
        end-time: uint,
        timezone: (string-ascii 6)
    })}
)

(define-map meetings
    { meeting-id: uint }
    { team-id: uint,
      organizer: principal,
      attendees: (list 50 principal),
      start-time: uint,
      end-time: uint,
      confirmed: bool }
)

(define-data-var meeting-nonce uint u0)

;; Private Functions
(define-private (is-team-member (team-id uint) (user principal))
    (let ((team (unwrap! (map-get? teams {team-id: team-id}) false)))
        (is-some (index-of (get members team) user))
    )
)

;; Public Functions
(define-public (create-team (name (string-ascii 64)))
    (let ((team-id (var-get meeting-nonce)))
        (var-set meeting-nonce (+ team-id u1))
        (ok (map-set teams
            { team-id: team-id }
            { name: name,
              owner: tx-sender,
              members: (list tx-sender) }))
    )
)

(define-public (add-team-member (team-id uint) (member principal))
    (let ((team (unwrap! (map-get? teams {team-id: team-id}) err-invalid-team)))
        (if (is-eq (get owner team) tx-sender)
            (ok (map-set teams
                { team-id: team-id }
                (merge team { members: (unwrap! (as-max-len? (append (get members team) member) u50) err-unauthorized) })))
            err-unauthorized
        )
    )
)

(define-public (set-availability (windows (list 10 {
        start-time: uint,
        end-time: uint,
        timezone: (string-ascii 6)
    })))
    (ok (map-set availability
        { user: tx-sender }
        { windows: windows }))
)

(define-public (schedule-meeting (team-id uint) (start-time uint) (end-time uint) (attendees (list 50 principal)))
    (let ((meeting-id (var-get meeting-nonce)))
        (if (is-team-member team-id tx-sender)
            (begin
                (var-set meeting-nonce (+ meeting-id u1))
                (ok (map-set meetings
                    { meeting-id: meeting-id }
                    { team-id: team-id,
                      organizer: tx-sender,
                      attendees: attendees,
                      start-time: start-time,
                      end-time: end-time,
                      confirmed: false })))
            err-unauthorized
        )
    )
)

(define-public (confirm-meeting (meeting-id uint))
    (let ((meeting (unwrap! (map-get? meetings {meeting-id: meeting-id}) err-invalid-slot)))
        (if (is-some (index-of (get attendees meeting) tx-sender))
            (ok (map-set meetings
                { meeting-id: meeting-id }
                (merge meeting { confirmed: true })))
            err-unauthorized
        )
    )
)

;; Read-only Functions
(define-read-only (get-team-info (team-id uint))
    (ok (map-get? teams {team-id: team-id}))
)

(define-read-only (get-user-availability (user principal))
    (ok (map-get? availability {user: user}))
)

(define-read-only (get-meeting-details (meeting-id uint))
    (ok (map-get? meetings {meeting-id: meeting-id}))
)