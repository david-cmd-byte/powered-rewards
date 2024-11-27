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