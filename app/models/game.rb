class Game < ApplicationRecord

    Rating = Struct.new(:rating, :rating_deviation, :volatility, :user_id)    
    before_save :update_ratings

    belongs_to :white, class_name: 'Player', foreign_key: 'white'
    belongs_to :black, class_name: 'Player', foreign_key: 'black'    

    private

        def update_ratings
            rating1, rating2 = calculate_rating(self.white, self.black, self.result)
            p1 = self.white
            p1.update_attributes(
                elo: rating1.rating,
                deviation: rating1.rating_deviation,
                volatility: rating1.volatility
            )

            p1.save
            
            p2 = self.black
            p2.update_attributes(
                elo: rating2.rating,
                deviation: rating2.rating_deviation,
                volatility: rating2.volatility
            )

            self.black.save
            
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