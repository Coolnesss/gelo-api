class GamesController < ApplicationController
  before_action :set_game, only: [:show, :update, :destroy]
  before_action :authorize
  before_action :authorize_self, only: [:confirm]

  # GET /games
  def index
    @games = Game.all

    render json: @games
  end

  # GET /games/1
  def show
    render json: @game
  end

  def confirm
    g = Game.find params[:id]
    g.confirmed = true
    if g.save
      render json: {status: :success}, status: :ok
    else
      render json: {status: "Something went wrong"}, status: :unprocessable_entity
    end
  end

  # GET /notifications
  def notifications
    games = current_user.unconfirmed_games

    render json: games, status: 200
  end

  # POST /games
  def create
    @game = Game.new_from_result(game_params, current_user)

    if @game.save
      render json: @game, status: :created, location: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  def my_games
    render json: current_user.games, status: 200
  end

  # PATCH/PUT /games/1
  def update
    if @game.update(game_params)
      render json: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # DELETE /games/1
  def destroy
    @game.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def game_params
      params.require(:game).permit(:opponent, :side, :whoWon)
    end
end
