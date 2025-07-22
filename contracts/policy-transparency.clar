;; Central Bank Policy Transparency Contract
;; Provides clear communication of monetary policy decisions

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-INPUT (err u501))
(define-constant ERR-POLICY-EXISTS (err u502))
(define-constant ERR-INVALID-RATE (err u503))
(define-constant ERR-COMMUNICATION-EXISTS (err u504))

;; Data Variables
(define-data-var current-interest-rate uint u250)
(define-data-var transparency-score uint u85)
(define-data-var total-policies uint u0)
(define-data-var total-communications uint u0)

;; Data Maps
(define-map policy-decisions
  { policy-id: uint }
  {
    decision-type: (string-ascii 64),
    description: (string-ascii 512),
    interest-rate-change: int,
    new-interest-rate: uint,
    rationale: (string-ascii 512),
    economic-indicators: (string-ascii 256),
    decision-date: uint,
    effective-date: uint,
    voting-record: (string-ascii 128),
    announced-by: principal
  }
)

(define-map policy-communications
  { communication-id: uint }
  {
    policy-id: uint,
    communication-type: (string-ascii 64),
    title: (string-ascii 128),
    content: (string-ascii 1024),
    target-audience: (string-ascii 64),
    publication-date: uint,
    clarity-score: uint,
    public-feedback: (string-ascii 512),
    published-by: principal
  }
)

(define-map implementation-tracking
  { tracking-id: uint }
  {
    policy-id: uint,
    implementation-stage: (string-ascii 64),
    progress-percentage: uint,
    milestones-completed: (list 10 (string-ascii 128)),
    challenges-faced: (string-ascii 512),
    market-response: (string-ascii 256),
    last-updated: uint,
    updated-by: principal
  }
)

(define-map transparency-metrics
  { metric-date: uint }
  {
    communication-frequency: uint,
    clarity-average: uint,
    public-engagement: uint,
    policy-predictability: uint,
    market-understanding: uint,
    overall-transparency: uint,
    calculated-by: principal
  }
)

(define-map stakeholder-feedback
  { feedback-id: uint }
  {
    policy-id: uint,
    stakeholder-type: (string-ascii 64),
    feedback-content: (string-ascii 512),
    sentiment-score: uint,
    concerns-raised: (list 5 (string-ascii 128)),
    suggestions: (string-ascii 256),
    submission-date: uint,
    submitted-by: principal
  }
)

;; Private Functions
(define-private (calculate-clarity-score (content (string-ascii 1024)) (target-audience (string-ascii 64)))
  (let
    (
      (content-length (len content))
      (base-score (if (> content-length u500) u60 u80))
      (audience-bonus (if (is-eq target-audience "PUBLIC") u20 u10))
    )
    (if (<= (+ base-score audience-bonus) u100)
      (+ base-score audience-bonus)
      u100
    )
  )
)

(define-private (update-transparency-metrics (new-clarity-score uint))
  (let
    (
      (current-transparency (var-get transparency-score))
      (updated-score (/ (+ current-transparency new-clarity-score) u2))
    )
    (var-set transparency-score updated-score)
  )
)

;; Public Functions
(define-public (record-policy (policy-id uint) (decision-type (string-ascii 64)) (description (string-ascii 512)) (interest-rate-change int) (rationale (string-ascii 512)) (economic-indicators (string-ascii 256)) (effective-date uint) (voting-record (string-ascii 128)))
  (let
    (
      (current-rate (var-get current-interest-rate))
      (new-rate (if (>= interest-rate-change 0)
                  (+ current-rate (to-uint interest-rate-change))
                  (if (>= current-rate (to-uint (- 0 interest-rate-change)))
                    (- current-rate (to-uint (- 0 interest-rate-change)))
                    u0)))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (> (len rationale) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? policy-decisions { policy-id: policy-id })) ERR-POLICY-EXISTS)
    (asserts! (<= new-rate u2000) ERR-INVALID-RATE)

    (map-set policy-decisions
      { policy-id: policy-id }
      {
        decision-type: decision-type,
        description: description,
        interest-rate-change: interest-rate-change,
        new-interest-rate: new-rate,
        rationale: rationale,
        economic-indicators: economic-indicators,
        decision-date: block-height,
        effective-date: effective-date,
        voting-record: voting-record,
        announced-by: tx-sender
      }
    )

    (var-set current-interest-rate new-rate)
    (var-set total-policies (+ (var-get total-policies) u1))

    (ok { policy-id: policy-id, new-interest-rate: new-rate })
  )
)

(define-public (update-communication (communication-id uint) (policy-id uint) (communication-type (string-ascii 64)) (title (string-ascii 128)) (content (string-ascii 1024)) (target-audience (string-ascii 64)))
  (let
    (
      (clarity-score (calculate-clarity-score content target-audience))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len content) u0) ERR-INVALID-INPUT)
    (asserts! (is-some (map-get? policy-decisions { policy-id: policy-id })) ERR-INVALID-INPUT)

    (map-set policy-communications
      { communication-id: communication-id }
      {
        policy-id: policy-id,
        communication-type: communication-type,
        title: title,
        content: content,
        target-audience: target-audience,
        publication-date: block-height,
        clarity-score: clarity-score,
        public-feedback: "",
        published-by: tx-sender
      }
    )

    (update-transparency-metrics clarity-score)
    (var-set total-communications (+ (var-get total-communications) u1))

    (ok { communication-id: communication-id, clarity-score: clarity-score })
  )
)

(define-public (track-implementation (tracking-id uint) (policy-id uint) (implementation-stage (string-ascii 64)) (progress-percentage uint) (milestones-completed (list 10 (string-ascii 128))) (challenges-faced (string-ascii 512)) (market-response (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? policy-decisions { policy-id: policy-id })) ERR-INVALID-INPUT)
    (asserts! (<= progress-percentage u100) ERR-INVALID-INPUT)

    (map-set implementation-tracking
      { tracking-id: tracking-id }
      {
        policy-id: policy-id,
        implementation-stage: implementation-stage,
        progress-percentage: progress-percentage,
        milestones-completed: milestones-completed,
        challenges-faced: challenges-faced,
        market-response: market-response,
        last-updated: block-height,
        updated-by: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (submit-stakeholder-feedback (feedback-id uint) (policy-id uint) (stakeholder-type (string-ascii 64)) (feedback-content (string-ascii 512)) (sentiment-score uint) (concerns-raised (list 5 (string-ascii 128))) (suggestions (string-ascii 256)))
  (begin
    (asserts! (is-some (map-get? policy-decisions { policy-id: policy-id })) ERR-INVALID-INPUT)
    (asserts! (> (len feedback-content) u0) ERR-INVALID-INPUT)
    (asserts! (<= sentiment-score u100) ERR-INVALID-INPUT)

    (map-set stakeholder-feedback
      { feedback-id: feedback-id }
      {
        policy-id: policy-id,
        stakeholder-type: stakeholder-type,
        feedback-content: feedback-content,
        sentiment-score: sentiment-score,
        concerns-raised: concerns-raised,
        suggestions: suggestions,
        submission-date: block-height,
        submitted-by: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (calculate-transparency-metrics (metric-date uint) (communication-frequency uint) (public-engagement uint) (policy-predictability uint) (market-understanding uint))
  (let
    (
      (clarity-average (var-get transparency-score))
      (overall-transparency (/ (+ communication-frequency clarity-average public-engagement policy-predictability market-understanding) u5))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= communication-frequency u100) ERR-INVALID-INPUT)
    (asserts! (<= public-engagement u100) ERR-INVALID-INPUT)
    (asserts! (<= policy-predictability u100) ERR-INVALID-INPUT)
    (asserts! (<= market-understanding u100) ERR-INVALID-INPUT)

    (map-set transparency-metrics
      { metric-date: metric-date }
      {
        communication-frequency: communication-frequency,
        clarity-average: clarity-average,
        public-engagement: public-engagement,
        policy-predictability: policy-predictability,
        market-understanding: market-understanding,
        overall-transparency: overall-transparency,
        calculated-by: tx-sender
      }
    )

    (var-set transparency-score overall-transparency)
    (ok { overall-transparency: overall-transparency })
  )
)

;; Read-only Functions
(define-read-only (get-policy (policy-id uint))
  (map-get? policy-decisions { policy-id: policy-id })
)

(define-read-only (get-communication (communication-id uint))
  (map-get? policy-communications { communication-id: communication-id })
)

(define-read-only (get-implementation-status (tracking-id uint))
  (map-get? implementation-tracking { tracking-id: tracking-id })
)

(define-read-only (get-transparency-metrics (metric-date uint))
  (map-get? transparency-metrics { metric-date: metric-date })
)

(define-read-only (get-stakeholder-feedback (feedback-id uint))
  (map-get? stakeholder-feedback { feedback-id: feedback-id })
)

(define-read-only (get-current-interest-rate)
  (var-get current-interest-rate)
)

(define-read-only (get-transparency-score)
  (var-get transparency-score)
)

(define-read-only (get-policy-statistics)
  {
    total-policies: (var-get total-policies),
    total-communications: (var-get total-communications),
    current-interest-rate: (var-get current-interest-rate),
    transparency-score: (var-get transparency-score)
  }
)

(define-read-only (get-policy-summary (policy-id uint))
  (match (map-get? policy-decisions { policy-id: policy-id })
    policy (ok {
      decision-type: (get decision-type policy),
      new-interest-rate: (get new-interest-rate policy),
      decision-date: (get decision-date policy),
      effective-date: (get effective-date policy)
    })
    (ok { decision-type: "", new-interest-rate: u0, decision-date: u0, effective-date: u0 })
  )
)
