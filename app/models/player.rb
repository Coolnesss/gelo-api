class Player < ApplicationRecord
    has_secure_password

    before_create :generate_token
    before_create :initial_ratings

    validates :username, uniqueness: true

    def games
        Game.where(white: self).or(Game.where(black: self))
    end

    def unconfirmed_games
        games.select do |game|
            !game.confirmed and game.added_by != self
        end
    end

    private
        def generate_token
            self.token = loop do
                random_token = SecureRandom.urlsafe_base64(nil, false)
                break random_token unless Player.exists?(token: random_token)
            end
        end

        def initial_ratings
            self.elo = 1500
            self.deviation = 350
            self.volatility = 0.06
        end
end
