class Player
    attr_accessor :name, :team, :model, :frags, :deaths, :ping
    attr_accessor :spectator, :priv, :positions
    def initialize
        @spectator = false
        @frags = @deaths = @damage_fired = @damage_inflicted = 0
        @positions = []
    end
    def shot_fired(damage)
        @damage_fired += damage
    end
    def shot_hit(damage)
        @damage_inflicted += damage
    end
    def accuracy
        n = 100.0 * @damage_inflicted / @damage_fired
        return n unless n.nan?
        0
    end
    def move(position)
        @positions << position
    end
end
