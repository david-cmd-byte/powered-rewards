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