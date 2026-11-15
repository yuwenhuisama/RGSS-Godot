output=Dir.pwd
Dir.chdir(TestPaths.game)
module Cache
  class << self
    alias compatibility_load_bitmap load_bitmap
    def load_bitmap(folder,filename,hue=0)
      unless filename.empty? || File.exist?(folder+filename+'.png')
        folder=TestPaths.rtp(folder)
      end
      compatibility_load_bitmap(folder,filename,hue)
    end
  end
end
module Audio
  class << self
    alias compatibility_se_play se_play
    def se_play(filename,volume=100,pitch=100)
      filename=TestPaths.rtp(filename) unless File.exist?(filename+'.ogg') || File.exist?(filename+'.wav')
      compatibility_se_play(filename,volume,pitch)
    end
  end
end
def capture_menu_reference(output,name)
  snap=Graphics.snap_to_bitmap
  File.open(File.join(output,name+'.rgba'),'wb') do |file|
    snap.height.times do |y|
      row=[];snap.width.times {|x|c=snap.get_pixel(x,y);row.concat([c.red.to_i,c.green.to_i,c.blue.to_i,c.alpha.to_i])}
      file.write(row.pack('C*'))
    end
  end
  snap.dispose
end
DataManager.init
DataManager.setup_new_game
SceneManager.goto(Scene_Map)
map=SceneManager.scene;map.start;map.post_start
60.times {map.update}
capture_menu_reference(output,'map_before')
map.call_menu;map.pre_terminate;map.terminate
menu=SceneManager.scene;menu.start;menu.post_start
60.times {menu.update}
capture_menu_reference(output,'menu')
SceneManager.return;menu.pre_terminate;menu.terminate
map=SceneManager.scene;map.start;map.post_start
60.times {map.update}
capture_menu_reference(output,'map_after')
map.pre_terminate;map.terminate
exit
