# D05 uses unmodified stock windows and their real update/input handlers.
# Host-side Marshal/Zlib extraction loads the source game's script table.
module D05Message
  CASES = %w[text choice choice-cancel number item item-cancel fast scroll scroll-no-fast]

  def self.prepare(output)
    @output = output
    @saved = [$data_system, $data_items, $data_weapons, $data_armors,
      $game_system, $game_message, $game_variables, $game_map, $game_party,
      $data_actors, $data_classes, $data_states, $data_skills, $game_actors]
    @font_saved = [Font.default_name, Font.default_size]
    Font.default_name = 'Arial'
    Font.default_size = 24
    $data_system = RPG::System.new
    $data_system.variables = [nil] + Array.new(10, 'D05 variable')
    $data_items = [nil]
    2.times do |i|
      item = RPG::Item.new
      item.id = i + 1
      item.name = i == 0 ? 'Copper key' : 'Silver key'
      item.itype_id = 2
      item.icon_index = i + 1
      $data_items << item
    end
    $data_weapons = [nil]
    $data_armors = [nil]
    actor = RPG::Actor.new
    actor.id = 1
    actor.name = 'D05 actor'
    actor.class_id = 1
    actor.equips = [0, 0, 0, 0, 0]
    actor_class = RPG::Class.new
    actor_class.id = 1
    100.times { |level| actor_class.params[0, level] = 100; actor_class.params[1, level] = 50 }
    $data_actors = [nil, actor]
    $data_classes = [nil, actor_class]
    $data_states = [nil]
    $data_skills = [nil]
    $game_actors = Game_Actors.new
    $game_system = Game_System.new
    $game_map = Game_Map.new
    $game_message = Game_Message.new
    $game_variables = Game_Variables.new
    $game_party = Game_Party.new
    $game_party.instance_variable_set(:@actors, [1])
    $game_actors[1].recover_all
    $game_party.gain_item($data_items[1], 1)
    $game_party.gain_item($data_items[2], 1)
    @backdrop = Sprite.new
    @backdrop.z = -1000
    @backdrop.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @backdrop.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0))
    @file = File.open(File.join(output, 'message_window_reference.tsv'), 'w')
  end

  def self.start(name)
    @name = name
    @frame = 0
    $game_message = Game_Message.new
    $game_variables[9] = 0
    $game_variables[2] = 9876
    $game_variables[3] = 99
    @message = Window_Message.new
    @scroll = Window_ScrollText.new
    @choice = @message.instance_variable_get(:@choice_window)
    @number = @message.instance_variable_get(:@number_window)
    @item = @message.instance_variable_get(:@item_window)
    commands = case name
    when 'text'
      [[101, 0, ['', 0, 0, 2]], [401, 0, ["\\>Page one\f\\>Page two\\!After pause\\^"]]]
    when 'fast'
      [[101, 0, ['', 0, 0, 2]], [401, 0, ['ABCDEFGHIJKLMNO\\^']]]
    when 'choice', 'choice-cancel'
      [[102, 0, [['Red', 'Blue'], 5]], [402, 0, [0, 'Red']], [122, 1, [1, 1, 0, 0, 11]],
       [402, 0, [1, 'Blue']], [122, 1, [1, 1, 0, 0, 22]],
       [403, 0, []], [122, 1, [1, 1, 0, 0, 33]], [404, 0, []]]
    when 'number'
      [[103, 0, [2, 3]]]
    when 'item', 'item-cancel'
      [[104, 0, [3]]]
    when 'scroll', 'scroll-no-fast'
      [[105, 0, [8, name == 'scroll-no-fast']], [405, 0, ['Scroll one']], [405, 0, ['Scroll two']]]
    else
      raise "Unknown D05 case #{name}"
    end
    commands << [122, 0, [9, 9, 0, 0, 77]]
    list = commands.map { |code, indent, parameters| RPG::EventCommand.new(code, indent, parameters) }
    list << RPG::EventCommand.new
    @interpreter = Game_Interpreter.new
    @interpreter.setup(list)
  end

  def self.step
    Input.update
    @interpreter.update
    @message.update
    @scroll.update
    row = [@name, @frame, @interpreter.running?, $game_message.busy?, $game_variables[9],
      @message.x, @message.y, @message.width, @message.height, @message.openness,
      @message.pause, @message.instance_variable_get(:@show_fast),
      @message.instance_variable_get(:@line_show_fast), @message.instance_variable_get(:@pause_skip),
      @choice.active, @choice.index, @choice.x, @choice.y, @choice.width, @choice.height, @choice.openness,
      @number.active, @number.instance_variable_get(:@number), @number.instance_variable_get(:@index),
      @number.x, @number.y, @number.width, @number.height, @number.openness,
      @item.active, @item.index, @item.item ? @item.item.id : 0, @item.y, @item.openness,
      @scroll.visible, @scroll.oy, @scroll.contents.height, @scroll.instance_variable_get(:@scroll_pos),
      $game_variables[1], $game_variables[2], $game_variables[3]]
    @file.puts(row.map { |value| value.is_a?(Float) ? sprintf('%.3f', value) : value.to_s }.join("\t"))
    @file.flush
    @frame += 1
  end

  def self.check(value, label)
    raise "D05 #{@name} frame #{@frame}: #{label}" unless value
  end

  def self.capture_choice_contents
    bitmap = @choice.contents
    File.open(File.join(@output, 'd05-choice-contents.rgba'), 'wb') do |file|
      bitmap.height.times do |y|
        bytes = []
        bitmap.width.times do |x|
          color = bitmap.get_pixel(x, y)
          bytes.concat([color.red.to_i, color.green.to_i, color.blue.to_i, color.alpha.to_i])
        end
        file.write(bytes.pack('C*'))
      end
    end
    File.open(File.join(@output, 'd05-choice-contents-size.txt'), 'w') { |file| file.puts(bitmap.width, bitmap.height) }
  end

  def self.blocked
    check(@interpreter.running? && $game_message.busy? && $game_variables[9] == 0, 'interpreter must block')
  end

  def self.completed
    check(!@interpreter.running? && !$game_message.busy? && $game_variables[9] == 77, 'interpreter must resume')
    check(@message.instance_variable_get(:@fiber).nil?, 'message fiber must finish')
    check(!@choice.active && !@number.active && !@item.active, 'subwindows must deactivate')
    check(@scroll.instance_variable_get(:@text).nil?, 'scroll must terminate')
  end

  def self.stop
    @message.dispose if @message
    @scroll.dispose if @scroll
    @message = @scroll = nil
  end

  def self.close
    stop
    @file.close if @file
    @backdrop.bitmap.dispose if @backdrop
    @backdrop.dispose if @backdrop
    Font.default_name, Font.default_size = @font_saved
    $data_system, $data_items, $data_weapons, $data_armors,
      $game_system, $game_message, $game_variables, $game_map, $game_party,
      $data_actors, $data_classes, $data_states, $data_skills, $game_actors = @saved
  end
end

# The original lacks a supported deterministic input injection surface here.
# Its run deliberately records only no-input states; it never fakes Input.*.
unless $d05_host
  begin
    module Cache
      class << self
        alias d05_original_load_bitmap load_bitmap
        def load_bitmap(folder, filename, hue = 0)
          folder = 'F:/Softwares/RPG Maker VX Ace/RTP/' + folder
          d05_original_load_bitmap(folder, filename, hue)
        end
      end
    end
    D05Message.prepare('.')
    D05Message::CASES.each do |name|
      D05Message.start(name)
      40.times { D05Message.step; Graphics.update }
      D05Message.capture_choice_contents if name == 'choice'
      if %w[text choice number item].include?(name)
        bitmap = Graphics.snap_to_bitmap
        File.open('d05-message-baseline-' + name + '.rgba', 'wb') do |file|
          bitmap.height.times do |y|
            bytes = []
            bitmap.width.times do |x|
              color = bitmap.get_pixel(x, y)
              bytes.concat([color.red.to_i, color.green.to_i, color.blue.to_i, color.alpha.to_i])
            end
            file.write(bytes.pack('C*'))
          end
        end
        File.open('d05-message-baseline-' + name + '-size.txt', 'w') { |file| file.puts(bitmap.width, bitmap.height) }
        bitmap.dispose
      end
      D05Message.stop
    end
    D05Message.close
    File.open('d05-message-original-complete.txt', 'w') { |file| file.puts('D05_MESSAGE_ORIGINAL_COMPLETE:360:no-input') }
  rescue Exception => error
    File.open('d05-message-original-error.txt', 'w') { |file| file.puts(error.class.to_s, error.message, error.backtrace) }
  end
  exit
end
