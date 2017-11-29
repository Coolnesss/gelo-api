class Game < ApplicationRecord

    Rating = Struct.new(:rating, :rating_deviation, :volatility, :user_id)
    before_save :update_ratings

    belongs_to :white, class_name: 'Player', foreign_key: 'white'
    belongs_to :black, class_name: 'Player', foreign_key: 'black'
    belongs_to :added_by, class_name: 'Player', foreign_key: 'added_by'

    validate :validate_unique_players
    validates :black, presence: true
    validates :white, presence: true

    def has_player?(u)
        self.white == u or self.black == u
    end

    def self.new_from_result(game_params, current_user)
        opponent = Player.find_by_username game_params["opponent"]
        g = Game.new
        g.added_by = current_user
        if game_params["side"] == "white"
            g.white = current_user
            g.black = opponent
        else
            g.white = opponent
            g.black = current_user
        end
        g.result = 1
        if game_params["whoWon"] == "black"
            g.result = -1
        elsif  game_params["whoWon"] == "draw"
            g.result = 0
        end
        g
    end

    private

        def validate_unique_players
            errors.add(:white, "Players must be different") if self.white == self.black
        end

        def update_ratings
            rating1, rating2 = calculate_rating(self.white, self.black, self.result)
            p1 = self.white
            p1.update_attributes(
                elo: rating1.rating,
                deviation: rating1.rating_deviation,
                volatility: rating1.volatility
            )

            p2 = self.black
            p2.update_attributes(
                elo: rating2.rating,
                deviation: rating2.rating_deviation,
                volatility: rating2.volatility
            )
        end

        def calculate_rating(player1, player2, winner)
            rating1 = Rating.new(player1.elo, player1.deviation, player1.volatility, player1.id)
            rating2 = Rating.new(player2.elo, player2.deviation, player2.volatility, player2.id)

            # Rating period with all participating ratings
            period = Glicko2::RatingPeriod.from_objs [rating1, rating2]

            # Register a game
            score = [1, 2]
            if winner == -1
                score = [2, 1]
            elsif winner == 0
                score = [0, 0]
            end

            period.game([rating1, rating2], score)

            # Generate the next rating period with updated players
            next_period = period.generate_next(0.5)

            # Update all Glicko ratings
            next_period.players.each { |p| p.update_obj }

            # Output updated Glicko ratings
            [rating1, rating2]
        end
end
