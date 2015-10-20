require 'gob'

Projectile = Gob:extend("Projectile")


function Projectile:init(opts)
  Projectile.super.init(self, opts)
  self.owner = opts.owner
end


function Projectile:collidesWith(b)
    if b == self.owner then
        return "cross"
    else
        return "touch"
    end
end


function Projectile:collide(cols)
    Projectile.super.collide(self, cols)

    for _, col in pairs(cols) do
        if col.other ~= self.owner then
            World:despawn(self)
            break
        end
    end
end
