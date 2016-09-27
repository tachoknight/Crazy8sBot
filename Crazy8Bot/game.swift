//
//  game.swift
//  Crazy8s
//

import Foundation

class Crazy8Game {
    
    let SHUFFLECOUNT = 1000
    
    var playerCount = 0
    var cardCount = 0
    var decksCount = 0
    
    var gameNumber = 0
    
    // The acual players of the game
    var players = [Player]()
    
    // The actual deck of cards
    var deck = createDeck()
    
    init() {
        #if os(Linux)
            srand(UInt32(time(nil)))
        #endif
    }
    
    private func setupGame() {
        calculateDeckCount()
        createDecks()
        shuffleDecks()
        
        setupPlayers()
        dealCards()
    }
    
    convenience init(playerCount withPlayerCount: Int) {
        self.init()
        
        self.playerCount = withPlayerCount
        self.cardCount = 8
        
        setupGame()
    }
    
    convenience init(playerCount withPlayerCount: Int, gameNumber: Int) {
        self.init()
        
        showOutput("Starting game \(gameNumber) with \(withPlayerCount) players")
        
        self.playerCount = withPlayerCount
        self.cardCount = 8
        self.gameNumber = gameNumber
        
        setupGame()
    }
    
    private func calculateDeckCount() {
        guard self.playerCount != 0 else {
            print("Need to set the player count first")
            return
        }
        
        self.decksCount = Int(Double(self.playerCount) * (1.0/4.0))
        showOutput("Game \(self.gameNumber) - Deck count is \(self.decksCount)")
    }
    
    private func createDecks() {
        var decks = 0
        repeat {
            #if os(Linux)
                self.deck.append(contentsOf: createDeck())
            #else
                self.deck.append(contentsOf: createDeck())
            #endif
            decks += 1
        } while decks < self.decksCount
        #if DEBUG
            showOutput("Game \(self.gameNumber) - Deck size is \(self.deck.count)")
        #endif
    }
    
    private func shuffleDecks() {
        showOutput("\(self.gameNumber) Now shuffling the deck...")
        
        self.deck = {
            var shuffleLoop = 1
            repeat {
                self.deck.shuffle()
                shuffleLoop += 1
                if shuffleLoop % 100 == 0 {
                    showOutput("Game \(self.gameNumber) - ...shuffle shuffle shuffle...")
                }
            } while shuffleLoop < self.SHUFFLECOUNT
            
            return self.deck
        }()
    }
    
    private func setupPlayers() {
        for idx in 1 ... self.playerCount {
            let player = Player()
            player.name = "Player \(idx)"
            players.append(player)
        }
    }
    
    private func dealCards() {
        var playerNum = 0
        for _ in 1 ... (self.cardCount * self.playerCount) {
            let card = self.deck.removeFirst()
            self.players[playerNum].hand.append(card)
            playerNum += 1
            if playerNum == self.playerCount {
                playerNum = 0
            }
        }
    }
    
    func playGame() {
        // Our boolean to determine if anyone won
        var gameOver = false
        
        // Where the cards are gonna go...
        var discardPile: [Card] = []
        
        // First person to play is next to the dealer (which
        // we will assume is 0)
        var currentPlayer = 1
        
        // This is the card we're going to play, whether it's
        // from the discard pile or from the deck
        //
        // We're getting the very first card from the deck that
        // everyone will play on in the loop below
        //
        var currentCard = self.deck.removeFirst()
        
        // We need to keep track of the suit separately from the played
        // card because a player may play an 8 and declare a new suit,
        // which the next player has to know about
        var currentSuit = currentCard.suit
        
        // The count of turns in the game
        var gameTurns = 0
        
        var shuffleLoop = 1
        
        showOutput("***** G A M E  \(self.gameNumber)  S T A R T I N G *****")
        
        //
        // And here begins the game
        //
        repeat {
            var turnOver = false
            
            //
            // Here begins a turn for a player
            //
            repeat {
                // Increment the turn count for the whole game
                gameTurns += 1
                
                // Can the player use this card?
                #if os(Linux)
                    let turn = players[currentPlayer].canPlayOn(currentCard, orSuit: currentSuit)
                #else
                    let turn = players[currentPlayer].canPlayOn(currentCard, orSuit: currentSuit)
                #endif
                
                // Do we have any cards in the deck?
                if self.deck.count == 0 {
                    // No, the deck is empty, so we need to
                    // transfer the discard pile back to the
                    // main deck...
                    showOutput("Game \(self.gameNumber) - Deck is empty, shuffling the discard pile...")
                    
                    self.deck = discardPile
                    // And reshuffle the deck
                    shuffleLoop = 0
                    repeat {
                        self.deck.shuffle()
                        shuffleLoop += 1
                    } while shuffleLoop < self.SHUFFLECOUNT
                    // And clear out the discard pile
                    discardPile.removeAll()
                }
                
                if turn.successful {
                    // The player has a card that they can put on the
                    // discard pile!
                    discardPile.append(turn.card!)
                    
                    // And the current card is what's on the top of the
                    // discard pile
                    currentCard = discardPile.last!
                    
                    // And set the suit we're telling the players to play
                    currentSuit = turn.newSuit!
                    
                    // And the player's turn is over
                    turnOver = true
                } else {
                    // The player does not have a playable card, so
                    // we need to pull the next card from the deck and
                    // then let's see if that helps in the next round
                    // of play
                    self.players[currentPlayer].hand.append(self.deck.removeFirst())
                }
            } while turnOver == false
            
            // Is the current player out of cards? If so, the game is over
            if self.players[currentPlayer].hand.count == 0 {
                // Yep, they're out of cards, so this player won!
                showOutput("Game \(self.gameNumber) - \(self.players[currentPlayer].name) won!")
                gameOver = true
            } else {
                // The current player's turn is over, and the game
                // is *not* over, so move on to the next player
                currentPlayer += 1
                if currentPlayer == self.playerCount {
                    currentPlayer = 0
                }
            }
        } while gameOver == false
        
        showOutput("\(self.gameNumber) - Game took \(gameTurns) turns")
        showOutput("\(self.gameNumber) - ***** G A M E  O V E R *****")
        showOutput("ZZZZZZ")
    }
}
