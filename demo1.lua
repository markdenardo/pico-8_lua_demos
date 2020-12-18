


-- hero


function _draw()
	cls()
	rx = rnd(128)
	ry = rnd(128)
	
	hero = {}
	hero.x = rx
	hero.y = ry
	hero.sprite = 0

	spr(hero.sprite, hero.x, hero.y)
	print(hero)
	print("hero position")
	print(hero.x)
end

