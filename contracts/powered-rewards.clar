;; title: Powered Gaming Ecosystem Smart Contract
;; summary: A secure smart contract for managing a gaming ecosystem with NFTs, player registration, score tracking, and reward distribution.
;; description: Enhanced version with improved input validation and security checks.

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-INVALID-SCORE (err u9))
(define-constant ERR-INVALID-FEE (err u10))
(define-constant ERR-INVALID-ENTRIES (err u11))

;; Storage for game configuration and state
(define-data-var game-fee uint u10)  ;; Entry fee in STX
(define-data-var max-leaderboard-entries uint u50)
(define-data-var total-prize-pool uint u0)

;; NFT trait implementation
(define-non-fungible-token game-asset uint)

;; Game Asset Metadata
(define-map game-asset-metadata 
  { token-id: uint }
  { 
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    power-level: uint
  }
)

;; Leaderboard structure
(define-map leaderboard 
  { player: principal }
  { 
    score: uint, 
    games-played: uint,
    total-rewards: uint 
  }
)

;; Whitelist for game creators and administrators
(define-map game-admin-whitelist principal bool)

;; Authorization check
(define-private (is-game-admin (sender principal))
  (default-to false (map-get? game-admin-whitelist sender))
)

;; Validate input strings
(define-private (is-valid-string (input (string-ascii 200)))
  (> (len input) u0)
)

;; Validate principal
(define-private (is-valid-principal (input principal))
  (not (is-eq input tx-sender))
)

;; Add game administrator with enhanced validation
(define-public (add-game-admin (new-admin principal))
  (begin
    ;; Ensure only existing admins can add new admins
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Validate the new admin principal
    (asserts! (is-valid-principal new-admin) ERR-INVALID-INPUT)
    
    ;; Add the new admin to the whitelist
    (map-set game-admin-whitelist new-admin true)
    (ok true)
  )
)

;; Mint new game asset NFT with enhanced validation
(define-public (mint-game-asset 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (rarity (string-ascii 20))
  (power-level uint)
)
  (let 
    (
      (token-id (+ (var-get total-game-assets) u1))
    )
    ;; Authorization check
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Input validation
    (asserts! (is-valid-string name) ERR-INVALID-INPUT)
    (asserts! (is-valid-string description) ERR-INVALID-INPUT)
    (asserts! (is-valid-string rarity) ERR-INVALID-INPUT)
    (asserts! (and (>= power-level u0) (<= power-level u1000)) ERR-INVALID-INPUT)
    
    ;; Mint NFT
    (try! (nft-mint? game-asset token-id tx-sender))
    
    ;; Store metadata
    (map-set game-asset-metadata 
      { token-id: token-id }
      {
        name: name,
        description: description, 
        rarity: rarity,
        power-level: power-level
      }
    )
    
    ;; Increment total assets
    (var-set total-game-assets token-id)
    
    (ok token-id)
  )
)

;; Transfer game asset with improved authorization
(define-public (transfer-game-asset (token-id uint) (recipient principal))
  (begin
    ;; Ensure only the owner can transfer
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? game-asset token-id) ERR-INVALID-GAME-ASSET))
      ERR-NOT-AUTHORIZED
    )
    
    ;; Validate recipient
    (asserts! (is-valid-principal recipient) ERR-INVALID-INPUT)
    
    ;; Perform transfer
    (nft-transfer? game-asset token-id tx-sender recipient)
  )
)

;; Player registration for game with enhanced checks
(define-public (register-player)
  (let 
    (
      (registration-fee (var-get game-fee))
    )
    ;; Check if player has sufficient funds
    (asserts! 
      (>= (stx-get-balance tx-sender) registration-fee) 
      ERR-INSUFFICIENT-FUNDS
    )
    
    ;; Check if player already registered
    (asserts! 
      (is-none (map-get? leaderboard { player: tx-sender }))
      ERR-ALREADY-REGISTERED
    )
    
    ;; Transfer registration fee
    (try! (stx-transfer? registration-fee tx-sender (as-contract tx-sender)))
    
    ;; Register player
    (map-set leaderboard 
      { player: tx-sender }
      {
        score: u0,
        games-played: u0,
        total-rewards: u0
      }
    )
    
    (ok true)
  )
)

;; Update player score with enhanced validation
(define-public (update-player-score 
  (player principal) 
  (new-score uint)
)
  (let 
    (
      (current-stats (unwrap! 
        (map-get? leaderboard { player: player }) 
        ERR-NOT-AUTHORIZED
      ))
    )
    ;; Authorization check
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Score validation
    (asserts! (and (>= new-score u0) (<= new-score u10000)) ERR-INVALID-SCORE)
    
    ;; Update leaderboard
    (map-set leaderboard 
      { player: player }
      (merge current-stats 
        {
          score: new-score,
          games-played: (+ (get games-played current-stats) u1)
        }
      )
    )
    
    (ok true)
  )
)

;; Distribute Bitcoin rewards with improved safety
(define-public (distribute-bitcoin-rewards)
  (let 
    (
      (top-players (get-top-players))
    )
    ;; Authorization check
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Placeholder for Bitcoin reward distribution logic
    ;; In a real implementation, this would interact with a Bitcoin bridge
    (fold distribute-reward top-players true)
    
    (ok true)
  )
)

;; Helper function to distribute rewards
(define-private (distribute-reward 
  (player principal) 
  (previous-result bool)
)
  ;; Additional validation: Ensure the player is registered in the leaderboard
  (match (map-get? leaderboard { player: player })
    player-stats 
      (let 
        (
          ;; Additional authorization check (optional)
          (is-valid-player 
            (and 
              (is-some (map-get? leaderboard { player: player }))
              (> (get score player-stats) u0)  ;; Optional: Only distribute to players with a score
            )
          )
          (reward-amount 
            (if is-valid-player 
              (calculate-reward (get score player-stats)) 
              u0
            )
          )
        )
        ;; Update total rewards only for valid players
        (if is-valid-player
          (begin
            (map-set leaderboard 
              { player: player }
              (merge player-stats 
                { total-rewards: (+ (get total-rewards player-stats) reward-amount) }
              )
            )
            true
          )
          previous-result
        )
      )
    ;; If player not found in leaderboard, return previous result
    previous-result
  )
)

;; Calculate reward based on player's score with improved logic
(define-private (calculate-reward (score uint))
  (if (and (> score u100) (<= score u10000))
    (* score u10)  ;; More complex reward calculation possible
    u0
  )
)

;; Get top players with placeholder implementation
(define-read-only (get-top-players)
  (let 
    (
      (max-entries (var-get max-leaderboard-entries))
    )
    ;; This is a simplified implementation
    ;; A more sophisticated version would sort and select top players
    (list 
      tx-sender  ;; Placeholder - would be actual top players
    )
  )
)

;; Initialize game configuration with enhanced validation
(define-public (initialize-game 
  (entry-fee uint) 
  (max-entries uint)
)
  (begin
    ;; Authorization check
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Input validation
    (asserts! (and (>= entry-fee u1) (<= entry-fee u1000)) ERR-INVALID-FEE)
    (asserts! (and (>= max-entries u1) (<= max-entries u500)) ERR-INVALID-ENTRIES)
    
    ;; Set game parameters
    (var-set game-fee entry-fee)
    (var-set max-leaderboard-entries max-entries)
    
    (ok true)
  )
)

;; Global variables
(define-data-var total-game-assets uint u0)

;; Initial setup - first admin is contract deployer
(map-set game-admin-whitelist tx-sender true)