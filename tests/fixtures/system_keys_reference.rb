sprite=Sprite.new
sprite.bitmap=Bitmap.new(544,416)
sprite.bitmap.fill_rect(0,0,544,416,Color.new(30,80,130))
loop { Graphics.update; Input.update }
