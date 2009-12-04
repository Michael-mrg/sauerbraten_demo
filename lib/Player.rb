class Player
    attr_accessor :name, :team, :frags, :deaths, :info, :ping
    attr_accessor :spectator, :priv
    def initialize(name='', team='', model=0)
        @name = name
        @team = team
        @model = model
        @info = []
        @spectator = false
        @frags = @deaths = @damage_fired = @damage_inflicted = 0
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
    def spectator?
        @spectator or (not @info.empty? and @info[0] == 1)
    end
end
