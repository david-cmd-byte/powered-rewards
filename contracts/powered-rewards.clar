;; title: Powered Gaming Ecosystem Smart Contract
;; summary: A smart contract for managing a gaming ecosystem with NFTs, player registration, score tracking, and reward distribution.
;; description: This contract allows game administrators to manage game assets, register players, update scores, and distribute rewards. It includes functionalities for minting NFTs, maintaining a leaderboard, and distributing Bitcoin rewards to top players.

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))

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

;; Add game administrator
(define-public (add-game-admin (new-admin principal))
  (begin
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    (map-set game-admin-whitelist new-admin true)
    (ok true)
  )
)

;; Mint new game asset NFT
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
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
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

;; Transfer game asset
(define-public (transfer-game-asset (token-id uint) (recipient principal))
  (begin
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? game-asset token-id) ERR-INVALID-GAME-ASSET))
      ERR-NOT-AUTHORIZED
    )
    (nft-transfer? game-asset token-id tx-sender recipient)
  )
)

;; Player registration for game
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

;; Update player score and game statistics
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
      (updated-stats 
        (merge current-stats 
          {
            score: new-score,
            games-played: (+ (get games-played current-stats) u1)
          }
        )
      )
    )
    (asserts! (is-game-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    (map-set leaderboard 
      { player: player }
      updated-stats
    )
    
    (ok true)
  )
)

;; Distribute Bitcoin rewards
(define-public (distribute-bitcoin-rewards)
  (let 
    (
      (top-players (get-top-players))
    )
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
  (let 
    (
      (player-stats (unwrap! 
        (map-get? leaderboard { player: player }) 
        false
      ))
      (reward-amount (calculate-reward (get score player-stats)))
    )
    ;; Update total rewards
    (map-set leaderboard 
      { player: player }
      (merge player-stats 
        { total-rewards: (+ (get total-rewards player-stats) reward-amount) }
      )
    )
    
    true
  )
)